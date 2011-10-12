(ns AimaSearch.core)

(defn actions [state]
  (cond (= state "bologna") ["to-roma" "to-milano"]
        (= state "roma") ["to-firenze" "to-bologna" "to-milano"]
        (= state "milano") ["to-firenze" "to-bologna" "to-roma"]
        (= state "firenze") ["to-milano" "to-roma"]))


(defn result [state action]
  (subs action 3))


(defn breadth-first-choose [frontier]
  "Choose the shortest path in frontier"
  (first (sort-by count frontier)))


(defn graph-search [initial goal? choose actions result]
  (loop [frontier #{[initial]}
         explored #{}
         path [initial]
         state initial]
    (when state
      (if (goal? state)
        path     ; we're done
        (let [ntx-explored (conj explored state)
              ntx-frontier (loop [fro (disj frontier path)
                                  acts (actions state)]
                             (if (seq acts)
                               (recur
                                 (let [a (first acts)
                                       ntx-state (result state a)]
                                   (if (contains? ntx-explored ntx-state)
                                     fro
                                     (conj fro (conj path a ntx-state))))
                                 (rest acts))
                               fro))
              ntx-path (choose ntx-frontier)]
          (recur
            ntx-frontier
            ntx-explored
            ntx-path
            (last ntx-path)))))))
