(local EXAMPLE-MODULES
  [:world :systems :ui :audio :layout :pathfinding :main
   :constants :terrain :physics-world :camera
   :buildings :crane :scoring])

(var saved-love nil)
(var mouse-x 0)
(var mouse-y 0)
(var keys-down {})

(fn noop [] nil)

(fn make-font []
  (let [font {}]
    (setmetatable font {:__index
                        {:getWidth (fn [_ text] (if text (# text) 0))
                         :getHeight (fn [_] 12)}})
    font))

(fn make-source []
  (let [source {}]
    (setmetatable source {:__index {:stop noop :play noop}})
    source))

(fn make-sound-data []
  (let [data {}]
    (setmetatable data {:__index {:setSample noop}})
    data))

(fn mock-world-points [state ...]
  (let [px (. state :x)
        py (. state :y)
        args [...]
        n (# args)
        out []]
    (var i 1)
    (while (<= i n)
      (table.insert out (+ px (. args i)))
      (table.insert out (+ py (. args (+ i 1))))
      (set i (+ i 2)))
    (values (table.unpack out))))

(fn make-body [x y]
  (let [state {:x (or x 0) :y (or y 0) :angle 0 :destroyed false :user-data nil}
        body {}]
    (setmetatable body
                  {:__index
                   {:getX (fn [_] (. state :x))
                    :getY (fn [_] (. state :y))
                    :getAngle (fn [_] (. state :angle))
                    :setAngle (fn [_ a] (tset state :angle a))
                    :setAngularVelocity noop
                    :setLinearVelocity noop
                    :setPosition (fn [_ nx ny]
                                   (tset state :x nx)
                                   (tset state :y ny))
                    :setFixedRotation noop
                    :setBullet noop
                    :setGravityScale noop
                    :setAngularDamping noop
                    :setUserData (fn [_ d] (tset state :user-data d))
                    :getUserData (fn [_] (. state :user-data))
                    :isDestroyed (fn [_] (. state :destroyed))
                    :destroy (fn [_] (tset state :destroyed true))
                    :getWorldPoints (fn [_ ...] (mock-world-points state ...))}})
    body))

(fn make-world []
  (let [world {}]
    (setmetatable world {:__index {:update noop :destroy noop}})
    world))

(fn make-joint []
  (let [joint {:destroyed false :max-length 100}]
    (setmetatable joint
                  {:__index
                   {:setMotorEnabled noop
                    :setMaxMotorTorque noop
                    :setMotorSpeed noop
                    :setMaxLength (fn [_ len] (tset joint :max-length len))
                    :getMaxLength (fn [_] (. joint :max-length))
                    :isDestroyed (fn [_] (. joint :destroyed))
                    :destroy (fn [_] (tset joint :destroyed true))}})
    joint))

(fn make-fixture []
  (let [fixture {}]
    (setmetatable fixture
                  {:__index
                   {:setFriction noop
                    :setRestitution noop
                    :setFilterData noop}})
    fixture))

(fn make-shape [] {})

(fn make-physics []
  {:newWorld (fn [_gx _gy _sleep] (make-world))
   :newBody (fn [_world x y _type] (make-body x y))
   :newRectangleShape (fn [_ ...] (make-shape))
   :newCircleShape (fn [_ ...] (make-shape))
   :newFixture (fn [_body _shape _density] (make-fixture))
   :newRevoluteJoint (fn [_a _b _x _y _collide] (make-joint))
   :newRopeJoint (fn [_a _b _x1 _y1 _x2 _y2 _max _collide] (make-joint))})

(fn install! []
  (set saved-love _G.love)
  (let [font (make-font)
        screen-w 560
        screen-h 560]
    (set _G.love
         {:graphics {:setColor noop
                     :clear noop
                     :rectangle noop
                     :line noop
                     :circle noop
                     :polygon noop
                     :print noop
                     :setLineWidth noop
                     :getFont (fn [] font)
                     :getWidth (fn [] screen-w)
                     :getHeight (fn [] screen-h)}
          :sound {:newSoundData (fn [_sample-count _rate _bits _channels]
                                  (make-sound-data))}
          :audio {:newSource (fn [_data _kind] (make-source))}
          :mouse {:getPosition (fn [] mouse-x mouse-y)}
          :keyboard {:isDown (fn [key] (. keys-down key))}
          :event {:quit noop}
          :physics (make-physics)})))

(fn uninstall! []
  (set _G.love saved-love))

(fn set-mouse! [x y]
  (set mouse-x x)
  (set mouse-y y))

(fn set-keys-down! [key down?]
  (tset keys-down key down?))

(fn clear-input! []
  (set mouse-x 0)
  (set mouse-y 0)
  (set keys-down {}))

(fn clear-shared-modules! []
  (each [name _ (pairs package.loaded)]
    (when (and (= (type name) "string") (= (name:sub 1 7) "shared."))
      (tset package.loaded name nil))))

(fn clear-example-modules! []
  (each [_ name (ipairs EXAMPLE-MODULES)]
    (tset package.loaded name nil))
  (clear-shared-modules!))

{:install! install!
 :uninstall! uninstall!
 :set-mouse! set-mouse!
 :set-keys-down! set-keys-down!
 :clear-input! clear-input!
 :clear-example-modules! clear-example-modules!
 :clear-shared-modules! clear-shared-modules!}
