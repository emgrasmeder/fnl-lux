(import-macros
 {: deftest : assert-eq : assert-is : testing}
 :io.gitlab.andreyorst.fennel-test)

(fn mock-love []
  (var nsd-args nil)
  (var played false)
  (set _G.love
       {:sound
        {:newSoundData (fn [samples sample-rate bits channels]
                         (set nsd-args [samples sample-rate bits channels])
                         {:setSample (fn [_ _ _] nil)})}
        :audio
        {:newSource (fn [_ _]
                      {:stop (fn [] nil)
                       :play (fn [] (set played true))})}})
  {:nsd-args (fn [] nsd-args)
   :played? (fn [] played)})

(deftest play-beep-sound-data-test
  (testing "play-beep uses correct newSoundData signature"
    (let [mock (mock-love)
          audio (require :audio)
          sample-count (math.floor (* 44100 0.15))
          (ok err) (pcall audio.play-beep)]
      (assert-eq true ok)
      (assert-eq [sample-count 44100 16 1] (mock.nsd-args))
      (assert-eq true (mock.played?)))))
