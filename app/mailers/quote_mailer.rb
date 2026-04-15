class QuoteMailer < ApplicationMailer
  def share_with_pro(quote, property, recipient_email, sender_name, message = nil)
    @quote          = quote
    @property       = property
    @sender_name    = sender_name
    @message        = message
    @quote_print_url = print_property_quote_url(property, quote, host: default_url_options[:host])

    mail(
      to:      recipient_email,
      subject: "#{sender_name} partage un devis estimatif de rénovation — Ren0vate"
    )
  end
end
