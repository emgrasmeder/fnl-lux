(fn step-on-interval [state dt interval advance-fn!]
  (set state.step-timer (+ state.step-timer dt))
  (when (>= state.step-timer interval)
    (set state.step-timer (- state.step-timer interval))
    (advance-fn!)))

{:step-on-interval step-on-interval}
