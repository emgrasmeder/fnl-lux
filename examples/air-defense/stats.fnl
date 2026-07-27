(fn initial-stats []
  {:reds-killed 0
   :buildings-destroyed 0
   :turret-damage 0
   :friendly-damage 0
   :missiles-fired 0
   :missile-hits 0})

(fn record-red-killed! [stats]
  (tset stats :reds-killed (+ (. stats :reds-killed) 1)))

(fn add-turret-damage! [stats amount]
  (tset stats :turret-damage (+ (. stats :turret-damage) amount)))

(fn add-friendly-damage! [stats amount]
  (tset stats :friendly-damage (+ (. stats :friendly-damage) amount)))

(fn record-missile-fired! [stats]
  (tset stats :missiles-fired (+ (. stats :missiles-fired) 1)))

(fn record-missile-hit! [stats]
  (tset stats :missile-hits (+ (. stats :missile-hits) 1)))

(fn record-building-destroyed! [stats]
  (tset stats :buildings-destroyed (+ (. stats :buildings-destroyed) 1)))

{:initial-stats initial-stats
 :record-red-killed! record-red-killed!
 :add-turret-damage! add-turret-damage!
 :add-friendly-damage! add-friendly-damage!
 :record-missile-fired! record-missile-fired!
 :record-missile-hit! record-missile-hit!
 :record-building-destroyed! record-building-destroyed!}
