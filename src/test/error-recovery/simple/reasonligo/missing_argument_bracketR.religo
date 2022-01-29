type sum_aggregator = { counter : int, sum : int }

let counter = (n : int) : int => {
  let initial : sum_aggregator = { counter : 0, sum : 0 };
  let rec aggregate : (sum_aggregator => int) =
    (prev : sum_aggregator => prev.sum;
  aggregate (initial)
}

type sum_aggregator = { counter : int, sum : int }

let counter = (n : int) : int => {
  let initial : sum_aggregator = { counter : 0, sum : 0 };
  let rec aggregate : (sum_aggregator => int) =
    (prev : sum_aggregator) => {
      if (prev.counter <= n) {
        aggregate
          ({
            counter : prev.counter + 1,
            sum : prev.counter + prev.sum
          })
      }
      else { prev.sum }
    };
  aggregate (initial)
}