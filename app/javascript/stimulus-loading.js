export function definitionsFromContext(context) {
  return context
    .keys()
    .map((key) => context(key))
    .map((module) => module.default)
    .filter((value) => value)
}
