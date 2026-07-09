(local world-mod (require :world))
(local systems (require :systems))

(fn player-label [player]
  (tostring player))

(fn other-player [player]
  (if (= player :X) :O :X))

(fn trim [s]
  (string.gsub s "^%s*(.-)%s*$" "%1"))

(fn parse-move [input]
  (let [s (trim (or input ""))
        (x y) (s:match "^(%d+)%s*,%s*(%d+)$")]
    (if x
        (values x y)
        (s:match "^(%d+)%s+(%d+)$"))))

(fn print-turn [player game]
  (print (.. "it's " (player-label player) "'s turn"))
  (print (systems.format-board-line game.world game.cell-at)))

(fn announce-first-player [player]
  (print (.. (player-label player) " goes first!")))

(fn handle-move [game current-player invalid-msg]
  (let [input (io.read)]
    (if (not input)
        :quit
        (let [(row-str col-str) (parse-move input)]
          (if (not row-str)
              (do
                (print invalid-msg)
                current-player)
              (let [row (tonumber row-str)
                    col (tonumber col-str)]
                (if (systems.apply-move game current-player row col)
                    (if (systems.winner game)
                        :win
                        (if (systems.draw? game)
                            :draw
                            (other-player current-player)))
                    (do
                      (print invalid-msg)
                      current-player))))))))

(fn run-game []
  (math.randomseed (os.time))
  (let [first-player (if (= (math.random 2) 1) :X :O)
        game (world-mod.create-game-world)
        invalid-msg "you have to pick a valid move"]
    (announce-first-player first-player)
    (var current-player first-player)
    (var done false)
    (while (not done)
      (print-turn current-player game)
      (let [result (handle-move game current-player invalid-msg)]
        (case result
          :quit (set done true)
          :win (do
                 (print-turn current-player game)
                 (print (.. (player-label current-player) " wins!"))
                 (set done true))
          :draw (do
                  (print-turn current-player game)
                  (print "Draw!")
                  (set done true))
          player (set current-player player))))))

(run-game)
