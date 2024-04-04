export function until(conditionFunction) {

  const poll = resolve => {
    conditionFunction() ? resolve() : setTimeout(() => poll(resolve), 200);
  }

  return new Promise(poll);
}
