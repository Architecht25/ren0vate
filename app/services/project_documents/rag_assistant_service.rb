# V2 — Lot 5 : assistant conversationnel sur dossier (cahier des charges
# §4, §8.7). RÈGLE DE SÉCURITÉ NON NÉGOCIABLE (§8) : "les droits sont
# appliqués avant la recherche vectorielle (filtrage par utilisateur et
# visibilité), jamais après." — voir #call : la liste des
# project_document_id visibles par `user` (via ProjectDocumentPolicy::Scope,
# donc la MÊME matrice rôle x lot x visibilité que partout ailleurs dans
# l'app) est calculée EN PREMIER, et la recherche de similarité est
# restreinte par une clause WHERE dessus — un chunk d'un document interdit
# n'entre jamais dans le jeu de résultats, il n'est jamais filtré après coup.
module ProjectDocuments
  class RagAssistantService
    TOP_K = 6

    def initialize(user:, project:)
      @user = user
      @project = project
    end

    # Retourne { answer:, sources: [ProjectDocument] } — answer est nil si
    # aucun chunk accessible ne correspond, ou si Ai::Client/Voyage AI est
    # indisponible (jamais d'exception propagée à l'utilisateur).
    def ask(question)
      visible_document_ids = Pundit.policy_scope!(@user, ProjectDocument).where(project: @project).pluck(:id)
      return no_result if visible_document_ids.empty?

      query_embedding = Ai::EmbeddingClient.new.embed([question])&.first
      return no_result if query_embedding.nil?

      chunks = ProjectDocumentChunk
        .joins(:project_document_version)
        .where(project: @project)
        .where(project_document_versions: { project_document_id: visible_document_ids })
        .nearest_neighbors(:embedding, query_embedding, distance: "cosine")
        .limit(TOP_K)

      return no_result if chunks.empty?

      answer = generate_answer(question, chunks)
      { answer: answer, sources: chunks.map(&:project_document).uniq }
    end

    private

    def no_result
      { answer: nil, sources: [] }
    end

    def generate_answer(question, chunks)
      context = chunks.each_with_index.map { |c, i| "[Source #{i + 1} — #{c.project_document.title}]\n#{c.content}" }.join("\n\n")

      client = Ai::Client.new(project: @project, actor: @user)
      client.run(
        :rag_answer,
        system: system_prompt,
        messages: [{ role: "user", content: "Documents du chantier :\n\n#{context}\n\nQuestion : #{question}" }]
      )
    end

    def system_prompt
      <<~PROMPT
        Tu réponds à une question sur un chantier de rénovation à partir
        UNIQUEMENT des extraits de documents fournis. Cite toujours la
        source (ex: "[Source 2]") pour chaque affirmation. Si la réponse
        ne se trouve pas dans les extraits fournis, dis-le clairement —
        n'invente jamais d'information. Tu ne donnes ni avis juridique ni
        avis technique, seulement ce que disent les documents.
      PROMPT
    end
  end
end
