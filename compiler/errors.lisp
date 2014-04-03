(in-package :varjo)

;-----------EXAMPLE-----------;
(define-condition machine-error (error)
  ((machine-name :initarg :machine-name :reader machine-error-machine-name))
  (:report (lambda (condition stream)
             (format stream "There is a problem with ~A."
                     (machine-error-machine-name condition)))))
;------------HELPER-----------;

;;[TODO] need better arg test
(defmacro deferror (name (&rest args) error-string &body body)
  (unless (every #'symbolp args) (error "can only take simple args"))
  (loop :for arg :in args :do
     (setf body (subst `(,arg condition) arg body :test #'eq)))
  `(define-condition ,name (varjo-error)
     (,@(loop :for arg :in args :collect
           `(,arg :initarg ,(kwd arg) :reader ,arg)))
     (:report (lambda (condition stream)
                (declare (ignorable condition))
                (format stream ,(format nil "Varjo: ~a" error-string) ,@body)))))

(define-condition varjo-error (error) ())

;-----------------------------;

(define-condition missing-function-error (error)
  ((text :initarg :text :reader text)))

(deferror problem-with-the-compiler (target)
  "This shouldnt have been possible so this needs a bug report. Sorry about that~%~s" target)

(deferror cannot-compile (code)
  "Cannot compile the following code:~%~a" code)

(deferror no-function-returns (name)
  "Function '~a' did not specify any return types" name)

(deferror not-core-type-error (type-name)
  "Type ~a is not a core type and thus cannot end up in glsl src code
   It must end up being used or converted to something that resolves 
   to a glsl type." type-name)

(deferror invalid-function-return-spec (func spec)
    "Return type spec of function ~a is invalid:~%~a" func spec)

(deferror unknown-type-spec (type-spec)
    "Unknown specification for type: ~a" type-spec)

(deferror duplicate-name (name)
    "This name appears more than once in this form list ~a" name)

(deferror clone-global-env-error ()
    "Cannot clone the global environment")

(deferror clean-global-env-error ()
    "Cannot clean the global environment")

(deferror could-not-find-function (name)
    "No function called '~a' was found in this environment" name)

(deferror no-valid-function (name types)
    "There is no applicable method for the glsl function '~s'~%when called with argument types:~%~s " name types)

(deferror return-type-mismatch (name types returns)
    "Some of the return statements in function '~a' return different types~%~a~%~a" 
  name types returns)

(deferror non-place-assign (place val)
    "You cannot setf this: ~a ~%This was attempted as follows ~a"
  (current-line place)
  (gen-assignment-string place val))

(deferror setf-type-match (code-obj-a code-obj-b)
    "Currently varjo cannot handle changing the type through a setf due to the static nature of glsl.~%place: ~a  value: ~a"
  (code-type code-obj-a) (code-type code-obj-b))

(deferror cannot-not-shadow-core ()
    "You cannot shadow or replace core macros or special functions.")

(deferror out-var-name-taken (out-var-name)
    "The variable name '~a' is already taken and so cannot be used~%for an out variable" 
  out-var-name)

(deferror unknown-variable-type (name)
    "Could not establish the type of the variable: ~s" name)

(deferror var-type-mismatch (var-type code-obj)
    "Type specified does not match the type of the form~%~s~%~s"
  (code-type code-obj) var-type)

(deferror switch-type-error (test-obj keys)
    "In a switch statement the result of the test and the keys must all be either ints or uints:~%Test type: ~a~%Keys used: ~{~a~^,~}" (code-type test-obj) keys)

(deferror loop-will-never-halt (test-code test-obj)
    "The loop is using the following code as it's test.~%~a~%~%This will only ever result in a ~a which means the loop will never halt" test-code (type->type-spec (code-type test-obj)))

(deferror for-loop-simple-expression ()
    "Only simple expressions are allowed in the condition and update slots of a for loop")

(deferror for-loop-only-one-var ()
    "for loops can only iterate over one variable")

(deferror invalid-for-loop-type (decl-obj)
    "Invalid type ~a used as counter for for-loop"
  (code-type decl-obj))

(deferror no-version-in-context (env)
    "No supported version found in context:~%~a"
  (v-context env))

(deferror name-unsuitable (name)
    "Names of variables and functions must be only contain~%alpha-numeric characters and the hyphen character (-).~%They also may not start with 'gl-', 'fk-', or '-sc-' ~%Supplied Name: ~a~%" name)

(deferror unable-to-resolve-func-type (func-name args)
    "Unable to resolve the result type of function '~a' when called~%with the argument types:~%~a~%" func-name (mapcar #'code-type args))

(deferror out-var-type-mismatch (var-name var-types)
    "The out variable ~a is has been set with different types.~%Types used: ~a" var-name var-types)

(deferror fake-type-global (env)
    "fake types can not be added to the global environment")

(deferror invalid-context-symbol (context-symb)
    "Sorry but the symbol '~a' is not valid as a context specifier" context-symb)

(deferror args-incompatible (previous-args current-args)
    "Sorry but the output arguments from one stage are not compatible with the input arguments of the next.~%Out vars from previous stage: ~a~%In args from this stage: ~a" previous-args current-args)

(deferror invalid-shader-stage (stage)
    "Sorry but '~a' is not a valid shader stage" stage)

(deferror swizzle-keyword (item)
    "Swizzle expects a keyword to specify the components. Recieved ~a instead" item) 
