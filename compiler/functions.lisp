(in-package :varjo)

(defconstant +order-bias+ 0.0001)

;;------------------------------------------------------------
;; GLSL Functions
;;----------------

(defun v-make-f-spec (transform args arg-types return-spec 
                      &key place glsl-spec-matching glsl-name required-glsl)
  (let* ((context-pos (position '&context args :test #'symbol-name-equal))
         (context (when context-pos (subseq args (1+ context-pos))))
         (args (if context-pos (subseq args 0 context-pos) args)))
    (declare (ignore args))
    (list transform arg-types return-spec context place glsl-spec-matching 
          glsl-name required-glsl)))
;;
;; {IMPORTANT NOTE} IF YOU CHANGE ONE-^^^^, CHANGE THE OTHER-vvvvv
;;
;;[TODO] split each case into a different macro and use this as core
;;[TODO] use make-func-spec so we have only one place where the spec
;;       is defined, this will lower the number of errors once we start
;;       editting things in the future
;;[TODO] This is the ugliest part of varjo now....sort it out!
(defmacro v-defun (name args &body body)
  (let* ((context-pos (position '&context args :test #'symbol-name-equal))
         (context (when context-pos (subseq args (1+ context-pos))))
         (args (subst '&rest '&body 
                      (if context-pos (subseq args 0 context-pos) args)
                      :test #'symbol-name-equal))
         (arg-names (lambda-list-get-names args)))
    (cond ((stringp (first body))
           (destructuring-bind (transform arg-types return-spec 
                                          &key place glsl-spec-matching glsl-name) body
             `(progn (add-function ',name '(,transform ,arg-types ,return-spec
                                            ,context ,place ,glsl-spec-matching 
                                            ,glsl-name nil)
                                   *global-env*)
                     ',name)))
          ((eq (first body) :special)
           (destructuring-bind (&key context place args-valid return)
               (rest body)
             (if (eq args-valid t)
                 `(progn 
                        (add-function ',name (list :special 
                                                   t
                                                   (lambda ,(cons 'env args) 
                                                     (declare (ignorable env ,@arg-names)) 
                                                     ,return)
                                                   ,context ,place nil nil nil)
                                      *global-env*)
                        ',name)
                 (if args-valid
                     `(progn 
                        (add-function ',name (list :special 
                                                   (lambda ,(cons 'env args)
                                                     (declare (ignorable env ,@arg-names))
                                                     (let ((res ,args-valid)) 
                                                       (when res (list res 0))))
                                                   (lambda ,(cons 'env args) 
                                                     (declare (ignorable env ,@arg-names)) 
                                                     ,return)                                               
                                                   ,context ,place nil nil nil)
                                      *global-env*)
                        ',name)
                     `(progn
                        (add-function ',name (list :special 
                                                   ',(mapcar #'second args)
                                                   (lambda ,(cons 'env (mapcar #'first args))
                                                     (declare (ignorable env ,@arg-names))
                                                     ,return)
                                                   ,context ,place nil nil nil)
                                      *global-env*)
                        ',name)))))
          (t `(progn (v-def-external ,name ,args ,@body)
                     ',name)))))

;;------------------------------------------------------------
;; External functions go through a full compile and then their
;; definition is extracted and added to the global environment.
;; This means they can then be used in future shader and 
;; other external functions

(defmacro v-def-external (name args &body body)
  `(%v-def-external ',name ',args ',body))

(defun %v-def-external (name args body)
  (let ((env (make-instance 'environment))
        (body `(%make-function ,name ,args ,@body)))
     (pipe-> (args body env)
       #'split-input-into-env
       (equal #'macroexpand-pass
              #'compiler-macroexpand-pass)
       #'compile-pass
       #'filter-used-items
       #'populate-required-glsl)))

(defun populate-required-glsl (code env)
  ;; {TODO} this shouldnt return, it should just populate. Why? I havent justified this
  (destructuring-bind (name func) (first (v-functions env))
    (add-function name
                  (function->func-spec 
                   func :required-glsl (list (signatures code) (to-top code)))
                  *global-env* t)
    (make-instance 'varjo-compile-result :glsl-code "" :stage-type nil :in-args nil
                   :out-vars nil :uniforms nil :context nil
                   :used-external-functions (used-external-functions code))))

;;This allows the addition of handwritten glsl 
(defmacro v-def-raw-glsl-func (name args return-type &body glsl)
  (%v-def-raw-external name args return-type (apply #'concatenate 'string glsl)))

(defun %v-def-raw-external (name args return-type glsl-string)
  (let* ((glsl-name (safe-glsl-name-string (free-name name)))
         (return-type (type-spec->type return-type))
         (arg-glsl-names (loop :for (name) :in args :collect
                            (safe-glsl-name-string name)))
         (arg-pairs (loop :for (ignored type) :in args
                       :for name :in arg-glsl-names :collect
                       `(,(v-glsl-string (type-spec->type type)) ,name))))
    (add-function 
     name
     (v-make-f-spec (gen-function-transform glsl-name args) args
                          (mapcar #'second args) return-type :glsl-name glsl-name
                          :required-glsl 
                          `((,(gen-function-signature glsl-name arg-pairs return-type))
                            (,(gen-glsl-function-body-string
                               glsl-name arg-pairs return-type glsl-string))))
     *global-env* t)
    t))

;;------------------------------------------------------------

;;[TODO] The stemcell stuff feels like it has been just bodged in, 
;;       can we make this code read more naturally.

;;[TODO] Where should this live?
(defun get-stemcells (arg-objs final-types)
  (loop :for o :in arg-objs :for f :in final-types
     :if (typep (code-type o) 'v-stemcell) :collect `(,o ,f)))

;;[TODO] catch cannot-compiler errors only here
(defun try-compile-arg (arg env)
  (handler-case (varjo->glsl arg env)
    (varjo-error (e) (make-instance 'code :type (make-instance 'v-error :payload e)))))


(defun special-arg-matchp (func arg-code arg-objs arg-types any-errors env)
  (let ((method (v-argument-spec func))
        (env (clone-environment env)))
    (if (listp method)
        (when (not any-errors) (basic-arg-matchp func arg-types arg-objs env))
        (if (eq method t)
            (list t func arg-code nil)
            (handler-case (list 0 func (apply method (cons env arg-code)) nil) 
              (varjo-error () nil))))))

(defun glsl-arg-matchp (func arg-types arg-objs env)
  (let* ((spec-types (v-argument-spec func))
         (spec-generics (positions-if #'v-spec-typep spec-types))
         (g-dim (when spec-generics 
                  (when (v-typep (nth (first spec-generics) arg-types) 'v-array 
                                 env)
                    (v-dimensions (nth (first spec-generics) arg-types))))))
    (when (and (eql (length arg-objs) (length spec-types))
               (or (null g-dim)
                   (loop :for i :in spec-generics :always 
                      (equal (v-dimensions (nth i arg-types)) g-dim))))
      (if (loop :for a :in arg-types :for s :in spec-types :always 
             (v-typep a s env))
          (list 0 func (swap-stemcells arg-objs spec-types)
                (get-stemcells arg-objs spec-types))
          (let ((cast-types (loop :for a :in arg-types :for s :in spec-types 
                             :collect (v-casts-to a s env))))
            (when (not (some #'null cast-types))
              (list 1 func (loop :for obj :in arg-objs :for type :in cast-types
                              :collect (copy-code obj :type type))
                    (get-stemcells arg-objs cast-types))))))))

(defun swap-stemcells (args-objs types)
  (loop :for a :in args-objs :for type :in types
     :collect (if (typep (code-type a) 'v-stemcell) 
                  (copy-code a :type type)
                  (copy-code a))))

;; [TODO] should this always copy the arg-objs?
(defun basic-arg-matchp (func arg-types arg-objs env)
  (let ((spec-types (v-argument-spec func)))
    (when (eql (length arg-objs) (length spec-types))
      (if (loop :for a :in arg-types :for s :in spec-types :always (v-typep a s env))
          (list 0 func (swap-stemcells arg-objs spec-types)
                (get-stemcells arg-objs spec-types))
          (let ((cast-types (loop :for a :in arg-types :for s :in spec-types 
                               :collect (v-casts-to a s env))))
            (when (not (some #'null cast-types))
              (list 1 func (loop :for obj :in arg-objs :for type :in cast-types
                              :collect (copy-code obj :type type))
                    (get-stemcells arg-objs cast-types))))))))

(defun find-functions-for-args (func-name args-code env &aux matches)
  (let (arg-objs arg-types any-errors (potentials (get-function func-name env)))
    (if potentials
        (loop :for func :in potentials :for bias-count :from 0 :do
           (when (and (not arg-objs) (func-need-arguments-compiledp func))
             (setf arg-objs (loop :for i :in args-code :collect 
                               (try-compile-arg i env)))
             (setf arg-types (mapcar #'code-type arg-objs))
             (setf any-errors (some #'v-errorp arg-types)))           
           (let ((match (if (v-special-functionp func)
                            (special-arg-matchp func args-code arg-objs
                                                arg-types any-errors env)
                            (when (not any-errors)
                              (if (v-glsl-spec-matchingp func)
                                  (glsl-arg-matchp func arg-types arg-objs env)
                                  (basic-arg-matchp func arg-types arg-objs env))))))
             (if (eq (first match) t)
                 (return (list match))
                 (when match
                   (when (numberp (first match)) 
                     (setf (first match) (+ (first match)
                                            (* bias-count +order-bias+))))
                   (push match matches))))
           :finally (return (or matches (func-find-failure func-name arg-objs))))
        (error 'could-not-find-function :name func-name))))

;; if there were no candidates then pass errors back
(defun func-find-failure (func-name arg-objs)
  (loop :for arg-obj :in arg-objs
     :if (typep (code-type arg-obj) 'v-error) 
     :return `((t ,(code-type arg-obj) nil nil)) 
     :finally (return
                `((t ,(make-instance 'v-error :payload
                                         (make-instance 'no-valid-function
                                                        :name func-name
                                                        :types (mapcar #'code-type
                                                                       arg-objs)))
                         nil nil)))))

(defun find-function-for-args (func-name args-code env)
  "Find the function that best matches the name and arg spec given
   the current environment. This process simply involves finding the 
   functions and then sorting them by their appropriateness score,
   the lower the better. We then take the first one and return that
   as the function to use."
  (let* ((functions (find-functions-for-args func-name args-code env)))
    (destructuring-bind (score function arg-objs stemcells)
        (if (> (length functions) 1) 
            (first (sort functions #'< :key #'first))
            (first functions))
      (declare (ignore score))
      (when (some #'(lambda (x) (and (typep x 'code) (typep (code-type x) 'v-stemcell)))
                  arg-objs)
        (error "Leaking stemcells, fix thsi and remove this error ~a" arg-objs))
      (list function arg-objs stemcells))))

(defun glsl-resolve-func-type (func args env)
  "nil - superior type
   number - type of nth arg
   function - call the function
   (:element n) - element type of nth arg
   list - type spec"
  (let ((spec (v-return-spec func))
        (arg-types (mapcar #'code-type args)))
    (cond ((null spec) (apply #'find-mutual-cast-type arg-types))
          ((typep spec 'v-t-type) spec)
          ((numberp spec) (nth spec arg-types))
          ((functionp spec) (apply spec args))
          ((and (listp spec) (eq (first spec) :element))
           (v-element-type (nth (second spec) arg-types)))
          ((or (symbolp spec) (listp spec)) (type-spec->type spec :env env))
          (t (error 'invalid-function-return-spec :func func :spec spec)))))

;;[TODO] Maybe the error should be caught and returned, 
;;       in case this is a bad walk
(defun glsl-resolve-special-func-type (func args env)
  (let ((env (clone-environment env)))
    (multiple-value-bind (code-obj new-env)
        (handler-case (apply (v-return-spec func) (cons env args))
          (varjo-error (e) (invoke-debugger e)))
      (values code-obj (or new-env env)))))

;;------------------------------------------------------------
