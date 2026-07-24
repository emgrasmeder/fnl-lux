(local c (require :constants))
(local crane-mod (require :crane))

(fn lp []
  (when (and _G.love _G.love.physics) _G.love.physics))

(fn set-filter! [fixture category mask]
  (when (and fixture (. fixture :setFilterData))
    ((. fixture :setFilterData) fixture category mask 0)))

(fn make-fixture! [body shape density category mask]
  (let [physics (lp)
        fixture (when physics ((. physics :newFixture) body shape density))]
    (when fixture
      (when (. fixture :setFriction) ((. fixture :setFriction) fixture c.FIXTURE-FRICTION))
      (when (. fixture :setRestitution)
        ((. fixture :setRestitution) fixture c.FIXTURE-RESTITUTION))
      (set-filter! fixture category mask))
    fixture))

(fn body-angle [body]
  (if (and body (. body :getAngle)) ((. body :getAngle) body) c.ARM-REST-ANGLE))

(fn body-xy [body]
  (if (and body (. body :getX) (. body :getY))
      [((. body :getX) body) ((. body :getY) body)]
      [c.BASE-X c.BASE-Y]))

(fn arm-tip-xy [arm-body]
  (if (and arm-body (. arm-body :getWorldPoints))
      (let [(wx wy) ((. arm-body :getWorldPoints) arm-body c.ARM-LEN 0)]
        [wx wy])
      [c.BASE-X (- c.BASE-Y c.ARM-LEN)]))

(fn destroy-body! [body]
  (when body
    (when (and (. body :isDestroyed) (not ((. body :isDestroyed) body)))
      (when (. body :destroy) ((. body :destroy) body)))))

(fn destroy-joint! [joint]
  (when joint
    (when (and (. joint :isDestroyed) (not ((. joint :isDestroyed) joint)))
      (when (. joint :destroy) ((. joint :destroy) joint)))))

(fn clear-brick-bodies! [pw]
  (each [_ rec (ipairs (. pw :brick-records))]
    (destroy-body! (. rec :body)))
  (tset pw :brick-records []))

(fn create-ground! [physics world]
  (let [ground-body ((. physics :newBody) world 0 c.GROUND-Y "static")
        shape ((. physics :newRectangleShape) (/ c.WINDOW-W 2) 30 c.WINDOW-W 60)]
    (make-fixture! ground-body shape 0 c.CAT-GROUND
                   (+ c.CAT-BALL c.CAT-CRANE c.CAT-BRICK))
    ground-body))

(fn create-crane! [physics world]
  (let [pivot ((. physics :newBody) world c.BASE-X c.BASE-Y "static")
        arm ((. physics :newBody) world c.BASE-X c.BASE-Y "dynamic")
        arm-shape ((. physics :newRectangleShape) (/ c.ARM-LEN 2) 0 c.ARM-LEN c.ARM-THICK)]
    (when (. arm :setAngle) ((. arm :setAngle) arm c.ARM-REST-ANGLE))
    (when (. arm :setFixedRotation) ((. arm :setFixedRotation) arm false))
    (make-fixture! arm arm-shape c.ARM-DENSITY c.CAT-CRANE
                   (+ c.CAT-GROUND c.CAT-BRICK))
    (let [revolute ((. physics :newRevoluteJoint) pivot arm c.BASE-X c.BASE-Y false)]
      (when (. revolute :setMotorEnabled) ((. revolute :setMotorEnabled) revolute true))
      (when (. revolute :setMaxMotorTorque)
        ((. revolute :setMaxMotorTorque) revolute c.MOTOR-MAX-TORQUE))
      {:pivot pivot :arm arm :revolute revolute})))

(fn create-ball! [physics world]
  (let [start-y (- c.GROUND-Y c.CHAIN-LEN c.BALL-R 4)
        ball ((. physics :newBody) world c.BASE-X start-y "dynamic")
        shape ((. physics :newCircleShape) 0 0 c.BALL-R)]
    (when (. ball :setBullet) ((. ball :setBullet) ball true))
    (make-fixture! ball shape c.BALL-DENSITY c.CAT-BALL (+ c.CAT-GROUND c.CAT-BRICK))
    ball))

(fn create-rope! [physics arm ball]
  (let [[tx ty] (arm-tip-xy arm)
        [bx by] (body-xy ball)]
    ((. physics :newRopeJoint) arm ball tx ty bx by c.CHAIN-LEN false)))

(fn create! []
  (let [physics (lp)]
    (if (not physics)
        {:world nil :ground nil :arm nil :ball nil :revolute nil :rope nil :brick-records []}
        (let [world ((. physics :newWorld) 0 c.GRAVITY true)
              ground (create-ground! physics world)
              crane (create-crane! physics world)
              ball (create-ball! physics world)
              rope (create-rope! physics (. crane :arm) ball)]
          {:world world
           :ground ground
           :pivot (. crane :pivot)
           :arm (. crane :arm)
           :revolute (. crane :revolute)
           :ball ball
           :rope rope
           :brick-records []}))))

(fn spawn-brick! [pw x y hue lux-id]
  (let [physics (lp)]
    (when (and physics (. pw :world))
      (let [world (. pw :world)
            body ((. physics :newBody) world x y "dynamic")
            shape ((. physics :newRectangleShape) 0 0 c.BRICK-SIZE c.BRICK-SIZE)]
        (when (. body :setUserData) ((. body :setUserData) body {:lux-id lux-id :hue hue}))
        (when (. body :setFixedRotation) ((. body :setFixedRotation) body true))
        (make-fixture! body shape c.BRICK-DENSITY c.CAT-BRICK (+ c.CAT-GROUND c.CAT-CRANE c.CAT-BRICK))
        (table.insert (. pw :brick-records) {:body body :lux-id lux-id :hue hue})
        body))))

(fn apply-motor! [pw tip-x tip-y]
  (when (and (. pw :revolute) (. pw :arm))
    (let [target (crane-mod.target-angle tip-x tip-y c.BASE-X c.BASE-Y)
          speed (crane-mod.motor-speed (body-angle (. pw :arm)) target)]
      (when (. pw.revolute :setMotorSpeed)
        ((. pw.revolute :setMotorSpeed) (. pw :revolute) speed)))))

(fn reset-crane-and-ball! [pw]
  (when (. pw :arm)
    (when (. pw.arm :setAngle) ((. pw.arm :setAngle) (. pw :arm) c.ARM-REST-ANGLE))
    (when (. pw.arm :setAngularVelocity) ((. pw.arm :setAngularVelocity) (. pw :arm) 0))
    (when (. pw.arm :setLinearVelocity) ((. pw.arm :setLinearVelocity) (. pw :arm) 0 0)))
  (when (. pw :ball)
    (let [start-y (- c.GROUND-Y c.CHAIN-LEN c.BALL-R 4)]
      (when (. pw.ball :setPosition) ((. pw.ball :setPosition) (. pw :ball) c.BASE-X start-y))
      (when (. pw.ball :setLinearVelocity) ((. pw.ball :setLinearVelocity) (. pw :ball) 0 0))
      (when (. pw.ball :setAngularVelocity) ((. pw.ball :setAngularVelocity) (. pw :ball) 0))))
  (destroy-joint! (. pw :rope))
  (let [physics (lp)]
    (when (and physics (. pw :arm) (. pw :ball))
      (tset pw :rope (create-rope! physics (. pw :arm) (. pw :ball))))))

(fn settle! [pw]
  (when (and (. pw :world) (. pw.world :update))
    (for [_ 1 c.BRICK-SETTLE-STEPS]
      ((. pw.world :update) (. pw :world) c.BRICK-SETTLE-DT))))

(fn step! [pw tip-x tip-y dt]
  (apply-motor! pw tip-x tip-y)
  (when (and (. pw :world) (. pw.world :update))
    ((. pw.world :update) (. pw :world) dt)))

(fn brick-off-screen? [body]
  (let [[x y] (body-xy body)
        m c.OFF-SCREEN-MARGIN]
    (or (< x (- m))
        (> x (+ c.WINDOW-W m))
        (< y (- m))
        (> y (+ c.WINDOW-H m)))))

(fn despawn-off-screen! [pw]
  (let [removals {}
        kept-records []]
    (each [_ rec (ipairs (. pw :brick-records))]
      (if (brick-off-screen? (. rec :body))
          (do
            (tset removals (. rec :lux-id) true)
            (destroy-body! (. rec :body)))
          (table.insert kept-records rec)))
    (tset pw :brick-records kept-records)
    removals))

(fn destroy! [pw]
  (clear-brick-bodies! pw)
  (destroy-joint! (. pw :rope))
  (destroy-body! (. pw :ball))
  (destroy-body! (. pw :arm))
  (destroy-body! (. pw :pivot))
  (destroy-body! (. pw :ground))
  (when (and (. pw :world) (. pw.world :destroy))
    ((. pw.world :destroy) (. pw :world))))

{:create! create!
 :spawn-brick! spawn-brick!
 :settle! settle!
 :clear-brick-bodies! clear-brick-bodies!
 :step! step!
 :apply-motor! apply-motor!
 :reset-crane-and-ball! reset-crane-and-ball!
 :despawn-off-screen! despawn-off-screen!
 :destroy! destroy!
 :arm-tip-xy arm-tip-xy
 :body-xy body-xy
 :body-angle body-angle}
