(local unpack (or table.unpack _G.unpack))

(fn push-at [tab index v ...]
  (when v
    (tset tab index v)
    (local next-index (+ index 1))
    (push-at tab next-index ...)))

(fn push [tab ...]
  (local index (+ (# tab) 1))
  (push-at tab index ...))

(fn slice [tab beginning len]
  (local ret [])
  (local real-beginning (- beginning 1))
  (for [i 1 len]
    (tset ret i (. tab (+ real-beginning i))))
  ret)

(fn concat! [tab1 tab2]
  (local tab1-len (# tab1))
  (for [i 1 (# tab2)]
    (push-at tab1 (+ tab1-len i) (. tab2 i))))

(fn concat [tab1 tab2]
  (local result [])
  (local tab1-len (# tab1))
  (for [i 1 tab1-len]
    (push-at result 1 (. tab1 i)))
  (for [i 1 (# tab2)]
    (push-at result (+ tab1-len i) (. tab2 i)))
  result)

(fn get-genid [] (var x 0) (fn [] (set x (+ x 1)) x))

(fn all [list fun]
  (var result true)
  (var done false)
  (var i 1)
  (while (and result (not done))
    (local el (. list i))
    (when (not (fun el))
      (set result false)
      (set done true))
    (set i (+ i 1)))
  result)

(fn any [list fun]
  (var result false)
  (each [i el (ipairs list)]
    (when (fun el) (set result true)))
  result)

{:unpack unpack
 :push push
 :push-at push-at
 :slice slice
 :concat concat
 :concat! concat!
 :get-genid get-genid
 :all all
 :any any}
