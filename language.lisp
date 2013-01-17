;; This software is Copyright (c) 2012 Chris Bagley
;; (techsnuffle<at>gmail<dot>com)
;; Chris Bagley grants you the rights to
;; distribute and use this software as governed
;; by the terms of the Lisp Lesser GNU Public License
;; (http://opensource.franz.com/preamble.html),
;; known as the LLGPL.

(in-package :varjo)

(defun vlambda (&key in-args compatible-args arg-types-match
		  output-type transform)
  (list (mapcar #'flesh-out-type
		(mapcar #'second in-args))
	(flesh-out-type output-type)
	transform
	compatible-args
	arg-types-match))

(defun glsl-defun (&key name in-args compatible-args 
		     arg-types-match output-type transform)
  (let* ((func-spec (vlambda :in-args in-args 
			     :compatible-args compatible-args 
			     :arg-types-match arg-types-match
			     :output-type output-type
			     :transform transform)))
    (setf *glsl-functions*
	  (acons name (cons func-spec
			    (assocr name *glsl-functions*))
		 *glsl-functions*))))

(defun func-specs (name)
  (assocr name *glsl-functions*))

(defun vfunctionp (name)
  (not (null (func-specs name))))

(defun special-functionp (symbol)
  (not (null (gethash symbol *glsl-special-functions*))))

(defun funcall-special (symbol arg-objs)
  (funcall (gethash symbol *glsl-special-functions*)
	   arg-objs))

(defun register-special-function (symbol function)
  (setf (gethash symbol *glsl-special-functions*) 
	function))

(defmacro vdefspecial (name (code-var) &body body)
  `(register-special-function
    ',name
    (lambda (,code-var)
      ,@body)))

(defun register-substitution (symbol function)
  (setf *glsl-substitutions*
	(acons symbol function *glsl-substitutions*)))

(defun substitutionp (symbol)
  (not (null (assoc symbol *glsl-substitutions*))))

(defun substitution (symbol)
  (assocr symbol *glsl-substitutions*))

(defmacro vdefmacro (name lambda-list &body body)
  `(register-substitution
    ',name
    (lambda ,lambda-list
      ,@body)))

(defun varjo-type->glsl-type (type)
  (let ((principle (first type))
	(structure (second type))
	(len (third type)))
    (if (eq structure :array)
	(format nil "~a[~a]" principle (if len len ""))
	(format nil "~a" principle))))

;;------------------------------------------------------------
;; Core Language Definitions
;;---------------------------

(glsl-defun :name 'bool
            :in-args '((x ((:double :float :int :uint :bool
			    :bvec2 :bvec3 :bvec4))))
            :output-type :bool
            :transform "bool(~a)")

(glsl-defun :name 'double
            :in-args '((x ((:bool :float :int :uint :double))))
            :output-type :double
            :transform "double(~a)")

(glsl-defun :name 'float
            :in-args '((x ((:bool :double :int :uint :float
			    :vec2 :vec3 :vec4))))
            :output-type :float
            :transform "float(~a)")

(glsl-defun :name 'int
            :in-args '((x ((:bool :double :float :uint :int
			    :ivec2 :ivec3 :ivec4))))
            :output-type :int
            :transform "int(~a)")

(glsl-defun :name 'uint
            :in-args '((x ((:bool :double :float :int :uint
			    :uvec2 :uvec3 :uvec4))))
            :output-type :uint
            :transform "uint(~a)")

(glsl-defun :name 'uint
            :in-args '((x ((:bool :double :float :int :uint
			    :uvec2 :uvec3 :uvec4))))
            :output-type :uint
            :transform "uint(~a)")

(glsl-defun :name 'degrees
            :in-args '((radians ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "degrees(~a)")

(glsl-defun :name 'radians
            :in-args '((degrees ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "radians(~a)")

(glsl-defun :name 'sin
            :in-args '((angle ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "sin(~a)")

(glsl-defun :name 'cos
            :in-args '((angle ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "cos(~a)")

(glsl-defun :name 'tan
            :in-args '((angle ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "tan(~a)")

(glsl-defun :name 'asin
            :in-args '((x ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "asin(~a)")

(glsl-defun :name 'acos
            :in-args '((x ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "acos(~a)")

(glsl-defun :name 'atan
            :in-args '((y ((:float :vec2 :vec3 :vec4)))
		       (x ((:float :vec2 :vec3 :vec4))))
	    :compatible-args t
            :output-type '(0 nil nil)
            :transform "atan(~a, ~a)")

(glsl-defun :name 'atan
            :in-args '((y-over-x ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "atan(~a)")

(glsl-defun :name 'sinh
            :in-args '((angle ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "sinh(~a)")

(glsl-defun :name 'cosh
            :in-args '((angle ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "cosh(~a)")

(glsl-defun :name 'tanh
            :in-args '((angle ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "tanh(~a)")

(glsl-defun :name 'asinh
            :in-args '((angle ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "asinh(~a)")

(glsl-defun :name 'acosh
            :in-args '((angle ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "acosh(~a)")

(glsl-defun :name 'atanh
            :in-args '((angle ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "atanh(~a)")

(glsl-defun :name 'pow
            :in-args '((x ((:float :vec2 :vec3 :vec4)))
		       (y ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "pow(~a, ~a)")

(glsl-defun :name 'exp
            :in-args '((x ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "exp(~a)")

(glsl-defun :name 'log
            :in-args '((x ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "log(~a)")

(glsl-defun :name 'exp2
            :in-args '((x ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "exp2(~a)")

(glsl-defun :name 'log2
            :in-args '((x ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "log2(~a)")

(glsl-defun :name 'sqrt
            :in-args '((x ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "exp(~a)")

(glsl-defun :name 'inversesqrt
            :in-args '((x ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "inversesqrt(~a)")

(glsl-defun :name 'abs
            :in-args '((x ((:float :vec2 :vec3 :vec4
			    :int :ivec2 :ivec3 :ivec4))))
            :output-type '(0 nil nil)
            :transform "abs(~a)")

(glsl-defun :name 'sign
            :in-args '((x ((:float :vec2 :vec3 :vec4
			    :int :ivec2 :ivec3 :ivec4))))
            :output-type '(:float nil nil)
            :transform "sign(~a)")

(glsl-defun :name 'floor
            :in-args '((x ((:float :vec2 :vec3 :vec4))))
            :output-type '(:int nil nil)
            :transform "floor(~a)")

(glsl-defun :name 'trunc
            :in-args '((x ((:float :vec2 :vec3 :vec4))))
            :output-type '(:int nil nil)
            :transform "trunc(~a)")

(glsl-defun :name 'round
            :in-args '((x ((:float :vec2 :vec3 :vec4))))
            :output-type '(:int nil nil)
            :transform "round(~a)")

(glsl-defun :name 'round-even
            :in-args '((x ((:float :vec2 :vec3 :vec4))))
            :output-type '(:int nil nil)
            :transform "roundEven(~a)")

(glsl-defun :name 'ceil
            :in-args '((x ((:float :vec2 :vec3 :vec4))))
            :output-type '(:int nil nil)
            :transform "ceil(~a)")

(glsl-defun :name 'fract
            :in-args '((x ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "fract(~a)")

(glsl-defun :name 'mod
            :in-args '((x ((:float :vec2 :vec3 :vec4)))
		       (y ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "mod(~a, ~a)")

(glsl-defun :name 'min
            :in-args '((x ((:float :vec2 :vec3 :vec4
			    :int :ivec2 :ivec3 :ivec4
			    :uint :uvec2 :uvec3 :uvec4)))
		       (y ((:float :vec2 :vec3 :vec4
			    :int :ivec2 :ivec3 :ivec4
			    :uint :uvec2 :uvec3 :uvec4))))
	    :arg-types-match t
            :output-type '(0 nil nil)
            :transform "min(~a, ~a)")

(glsl-defun :name 'min
            :in-args '((x ((:float :vec2 :vec3 :vec4)))
		       (y :float))
            :output-type '(0 nil nil)
            :transform "min(~a, ~a)")

(glsl-defun :name 'min
            :in-args '((x ((:int :ivec2 :ivec3 :ivec4)))
		       (y :int))
            :output-type '(0 nil nil)
            :transform "min(~a, ~a)")

(glsl-defun :name 'min
            :in-args '((x ((:uint :uvec2 :uvec3 :uvec4)))
		       (y :uint))
            :output-type '(0 nil nil)
            :transform "min(~a, ~a)")

(glsl-defun :name 'max
            :in-args '((x ((:float :vec2 :vec3 :vec4
			    :int :ivec2 :ivec3 :ivec4
			    :uint :uvec2 :uvec3 :uvec4)))
		       (y ((:float :vec2 :vec3 :vec4
			    :int :ivec2 :ivec3 :ivec4
			    :uint :uvec2 :uvec3 :uvec4))))
	    :arg-types-match t
            :output-type '(0 nil nil)
            :transform "max(~a, ~a)")

(glsl-defun :name 'max
            :in-args '((x ((:float :vec2 :vec3 :vec4)))
		       (y :float))
            :output-type '(0 nil nil)
            :transform "max(~a, ~a)")

(glsl-defun :name 'max
            :in-args '((x ((:int :ivec2 :ivec3 :ivec4)))
		       (y :int))
            :output-type '(0 nil nil)
            :transform "max(~a, ~a)")

(glsl-defun :name 'max
            :in-args '((x ((:uint :uvec2 :uvec3 :uvec4)))
		       (y :uint))
            :output-type '(0 nil nil)
            :transform "max(~a, ~a)")

(glsl-defun :name 'clamp
            :in-args '((x ((:float :vec2 :vec3 :vec4
			    :int :ivec2 :ivec3 :ivec4
			    :uint :uvec2 :uvec3 :uvec4)))
		       (min-val ((:float :vec2 :vec3 :vec4
				  :int :ivec2 :ivec3 :ivec4
				  :uint :uvec2 :uvec3 :uvec4)))
		       (max-val ((:float :vec2 :vec3 :vec4
				  :int :ivec2 :ivec3 :ivec4
				  :uint :uvec2 :uvec3 :uvec4))))
	    :arg-types-match t
            :output-type '(0 nil nil)
            :transform "clamp(~a, ~a, ~a)")

(glsl-defun :name 'clamp
            :in-args '((x ((:float :vec2 :vec3 :vec4)))
		       (min-val :float)
		       (max-val :float))
	    :compatible-args t
            :output-type '(0 nil nil)
            :transform "clamp(~a, ~a, ~a)")

(glsl-defun :name 'clamp
            :in-args '((x ((:int :ivec2 :ivec3 :ivec4)))
		       (min-val :int)
		       (max-val :int))
	    :compatible-args t
            :output-type '(0 nil nil)
            :transform "clamp(~a, ~a, ~a)")

(glsl-defun :name 'clamp
            :in-args '((x ((:uint :uvec2 :uvec3 :uvec4)))
		       (min-val :uint)
		       (max-val :uint))
	    :compatible-args t
            :output-type '(0 nil nil)
            :transform "clamp(~a, ~a, ~a)")

(glsl-defun :name 'mix
            :in-args '((x ((:float :vec2 :vec3 :vec4)))
		       (y ((:float :vec2 :vec3 :vec4)))
		       (a ((:float :vec2 :vec3 :vec4))))
	    :arg-types-match t
            :output-type '(0 nil nil)
            :transform "mix(~a, ~a, ~a)")

(glsl-defun :name 'mix
            :in-args '((x ((:float :vec2 :vec3 :vec4)))
		       (y ((:float :vec2 :vec3 :vec4)))
		       (a ((:float :bvec2 :bvec3 :bvec4 :bool))))
            :output-type '(0 nil nil)
            :transform "mix(~a, ~a, ~a)")

(glsl-defun :name 'smooth-step
            :in-args '((edge0 ((:float :vec2 :vec3 :vec4)))
		       (edge1 ((:float :vec2 :vec3 :vec4)))
		       (x ((:float :vec2 :vec3 :vec4))))
	    :arg-types-match t
            :output-type '(2 nil nil)
            :transform "smoothstep(~a, ~a, ~a)")

(glsl-defun :name 'smooth-step
            :in-args '((edge0 :float)
		       (edge1 :float)
		       (x ((:float :vec2 :vec3 :vec4))))
            :output-type '(2 nil nil)
            :transform "smoothstep(~a, ~a, ~a)")

(glsl-defun :name 'is-nan
            :in-args '((x :float))
            :output-type '(:bool nil nil)
            :transform "isnan(~a, ~a, ~a)")

(glsl-defun :name 'is-nan
            :in-args '((x :vec2))
            :output-type '(:bvec2 nil nil)
            :transform "isnan(~a, ~a, ~a)")

(glsl-defun :name 'is-nan
            :in-args '((x :vec3))
            :output-type '(:bvec3 nil nil)
            :transform "isnan(~a, ~a, ~a)")

(glsl-defun :name 'is-nan
            :in-args '((x :vec4))
            :output-type '(:bvec4 nil nil)
            :transform "isnan(~a, ~a, ~a)")

(glsl-defun :name 'length
            :in-args '((x ((:float :vec2 :vec3 :vec4))))
            :output-type :float
            :transform "length(~a)")

(glsl-defun :name 'distance
            :in-args '((p0 ((:float :vec2 :vec3 :vec4)))
		       (p1 ((:float :vec2 :vec3 :vec4))))
	    :arg-types-match t
            :output-type :float
            :transform "distance(~a, ~a)")

(glsl-defun :name 'dot
            :in-args '((x ((:float :vec2 :vec3 :vec4)))
		       (y ((:float :vec2 :vec3 :vec4))))
	    :arg-types-match t
            :output-type :float
            :transform "dot(~a, ~a)")

(glsl-defun :name 'cross
            :in-args '((x :vec3)
		       (y :vec3))
            :output-type :vec3
            :transform "cross(~a, ~a)")

(glsl-defun :name 'normalize
            :in-args '((x ((:float :vec2 :vec3 :vec4))))
            :output-type '(0 nil nil)
            :transform "cross(~a, ~a)")

(glsl-defun :name 'f-transform
            :in-args '()
            :output-type :vec4
            :transform "ftransform()")

(glsl-defun :name '*
            :in-args '((x ((:int :float)))
		       (y ((:int :float))))
            :output-type '(0 nil nil)
            :transform "(~a * ~a)")

;; (glsl-defun :name '*
;;             :in-args '((x ((:int :float)))
;; 		       (y ((:vec2 :vec3 :vec4
;; 			   :ivec2 :ivec3 :ivec4))))
;;             :output-type '(0 nil nil)
;;             :transform "(~a * ~a)")

(glsl-defun :name '*
            :in-args '((x ((:int :float)))
		       (y ((:vec2 :vec3 :vec4
			    :ivec2 :ivec3 :ivec4
			    :mat2 :mat3 :mat4 
			    :mat2x2 :mat2x3 :mat2x4
			    :mat3x2 :mat3x3 :mat3x4
			    :mat4x2 :mat4x3 :mat4x4))))
            :output-type '(0 nil nil)
            :transform "(~a * ~a)")

(glsl-defun :name '*
            :in-args '((x ((:vec2 :vec3 :vec4
			    :ivec2 :ivec3 :ivec4
			    :mat2 :mat3 :mat4 
			    :mat2x2 :mat2x3 :mat2x4
			    :mat3x2 :mat3x3 :mat3x4
			    :mat4x2 :mat4x3 :mat4x4)))
		       (y ((:int :float))))
            :output-type '(0 nil nil)
            :transform "(~a * ~a)")

(glsl-defun :name '*
            :in-args '((x ((:vec2 :vec3 :vec4
			    :ivec2 :ivec3 :ivec4)))
		       (y ((:vec2 :vec3 :vec4
			    :ivec2 :ivec3 :ivec4))))
	    :compatible-args t
            :output-type '(0 nil nil)
            :transform "(~a * ~a)")

(glsl-defun :name '*
            :in-args '((x ((:mat2x2 :mat2x3 :mat2x4)))
		       (y ((:vec2 :ivec2))))
            :output-type '(0 nil nil)
            :transform "(~a * ~a)")

(glsl-defun :name '*
            :in-args '((x ((:mat3x2 :mat3x3 :mat3x4)))
		       (y ((:vec3 :ivec3))))
            :output-type '(0 nil nil)
            :transform "(~a * ~a)")

(glsl-defun :name '*
            :in-args '((x ((:mat4x2 :mat4x3 :mat4x4)))
		       (y ((:vec4 :ivec4))))
            :output-type '(0 nil nil)
            :transform "(~a * ~a)")


(glsl-defun :name '%
            :in-args '((x ((:int :uint :ivec2 :uvec2 
			    :ivec3 :uvec3 :ivec4 :uvec4)))
		       (y ((:int :uint))))
	    :compatible-args t
            :output-type '(0 nil nil)
            :transform "(~a % ~a)")

(glsl-defun :name '<
            :in-args '((x ((:float :int)))
		       (y ((:float :int))))
            :output-type '(:bool nil nil)
            :transform "(~a < ~a)")

(glsl-defun :name '>
            :in-args '((x ((:float :int)))
		       (y ((:float :int))))
            :output-type '(:bool nil nil)
            :transform "(~a > ~a)")

(glsl-defun :name '<=
            :in-args '((x ((:float :int)))
		       (y ((:float :int))))
            :output-type '(:bool nil nil)
            :transform "(~a <= ~a)")

(glsl-defun :name '>=
            :in-args '((x ((:float :int)))
		       (y ((:float :int))))
            :output-type '(:bool nil nil)
            :transform "(~a >= ~a)")

(glsl-defun :name '==
	    :in-args '((a (t t t))
		       (b (t t t)))
	    :compatible-args t
	    :output-type '(:bool nil nil)
	    :transform "(~a == ~a)")

(glsl-defun :name '!=
	    :in-args '((a (t t t))
		       (b (t t t)))
	    :compatible-args t
	    :output-type '(:bool nil nil)
	    :transform "(~a != ~a)")

(glsl-defun :name '!
	    :in-args '((a (:bool nil nil)))
	    :output-type '(:bool nil nil)
	    :transform "(! ~a)")

(glsl-defun :name '~
	    :in-args '((a ((:int :uint :ivec2 :ivec3 :ivec4) 
			   nil nil)))
	    :output-type '(0 nil nil)
	    :transform "(~ ~a)")

(glsl-defun :name '<<
	    :in-args '((a ((:int :uint :float) nil nil))
		       (b ((:int :uint :float) nil nil)))
	    :output-type '(0 nil nil)
	    :transform "(~a << ~a)")

(glsl-defun :name '<<
	    :in-args '((a ((:ivec2 :ivec3 :ivec4
			    :uvec2 :uvec3 :uvec4) nil nil))
		       (b ((:int :uint :float) nil nil)))
	    :output-type '(0 nil nil)
	    :transform "(~a << ~a)")

(glsl-defun :name '<<
	    :in-args '((a ((:ivec2 :ivec3 :ivec4
			    :uvec2 :uvec3 :uvec4) nil nil))
		       (b ((:ivec2 :ivec3 :ivec4
			    :uvec2 :uvec3 :uvec4) nil nil)))
	    :compatible-args t
	    :output-type '(0 nil nil)
	    :transform "(~a << ~a)")

(glsl-defun :name '>>
	    :in-args '((a ((:int :uint :float) nil nil))
		       (b ((:int :uint :float) nil nil)))
	    :output-type '(0 nil nil)
	    :transform "(~a >> ~a)")

(glsl-defun :name '>>
	    :in-args '((a ((:ivec2 :ivec3 :ivec4
			    :uvec2 :uvec3 :uvec4) nil nil))
		       (b ((:int :uint :float) nil nil)))
	    :output-type '(0 nil nil)
	    :transform "(~a >> ~a)")

(glsl-defun :name '>>
	    :in-args '((a ((:ivec2 :ivec3 :ivec4
			    :uvec2 :uvec3 :uvec4) nil nil))
		       (b ((:ivec2 :ivec3 :ivec4
			    :uvec2 :uvec3 :uvec4) nil nil)))
	    :compatible-args t
	    :output-type '(0 nil nil)
	    :transform "(~a >> ~a)")

(glsl-defun :name '&
	    :in-args '((a ((:int :uint
			    :ivec2 :ivec3 :ivec4
			    :uvec2 :uvec3 :uvec4) nil nil))
		       (b ((:int :uint
			    :ivec2 :ivec3 :ivec4
			    :uvec2 :uvec3 :uvec4) nil nil)))
	    :arg-types-match t
	    :output-type '(0 nil nil)
	    :transform "(~a & ~a)")

(glsl-defun :name '^
	    :in-args '((a ((:int :uint
			    :ivec2 :ivec3 :ivec4
			    :uvec2 :uvec3 :uvec4) nil nil))
		       (b ((:int :uint
			    :ivec2 :ivec3 :ivec4
			    :uvec2 :uvec3 :uvec4) nil nil)))
	    :arg-types-match t
	    :output-type '(0 nil nil)
	    :transform "(~a ^ ~a)")

(glsl-defun :name 'pipe
	    :in-args '((a ((:int :uint
			    :ivec2 :ivec3 :ivec4
			    :uvec2 :uvec3 :uvec4) nil nil))
		       (b ((:int :uint
			    :ivec2 :ivec3 :ivec4
			    :uvec2 :uvec3 :uvec4) nil nil)))
	    :arg-types-match t
	    :output-type '(0 nil nil)
	    :transform "(~a | ~a)")

(glsl-defun :name '&&
	    :in-args '((a (:bool nil nil))
		       (b (:bool nil nil)))
	    :output-type '(0 nil nil)
	    :transform "(~a && ~a)")

(glsl-defun :name '^^
	    :in-args '((a (:bool nil nil))
		       (b (:bool nil nil)))
	    :output-type '(0 nil nil)
	    :transform "(~a && ~a)")

(glsl-defun :name '||
	    :in-args '((a (:bool nil nil))
		       (b (:bool nil nil)))
	    :output-type '(0 nil nil)
	    :transform "(~a && ~a)")



;;------------------------------------------------------------
;; Special Function
;;------------------

(vdefspecial %progn (varjo-code)    
  (let ((arg-objs (mapcar #'varjo->glsl varjo-code)))
    (if (eq 1 (length arg-objs))
	(car arg-objs)
	(let ((last-arg (car (last arg-objs)))
	      (args (subseq arg-objs 0 (- (length arg-objs) 1))))
	  (make-instance 
	   'code 
	   :type (code-type last-arg)
	   :current-line (current-line last-arg)
	   :to-block (remove-if 
		      #'null
		      (append
		       (mapcan #'(lambda (x) 
				   (list (to-block x) 
					 (current-line x)))
			       args)
		       (list (to-block last-arg))))
	   :to-top (mapcan #'to-top arg-objs))))))

(vdefspecial %typify (varjo-code)    
  (let ((arg-objs (mapcar #'varjo->glsl varjo-code)))
    (if (> (length arg-objs) 1)
      (error "Typify cannot take more than one form")	
	(let* ((arg (car arg-objs))
	       (type (code-type arg)))
	  (make-instance 
	   'code 
	   :type type
	   :current-line (format nil "~a ~a" 
				 (varjo-type->glsl-type type)
				 (current-line arg))
	   :to-block (to-block arg)
	   :to-top (to-top arg))))))


(vdefspecial %make-var (varjo-code)  
  (if (> (length varjo-code) 1)
      (error "Make-var cannot take more than one form")
      (let ((form (first varjo-code)))
	(if (listp form)
	    (let ((name (first form))
		  (type (second form)))
	      (make-instance 'code 
			     :type type
			     :current-line (format nil "~a" name)))
	    (make-instance 'code 
			   :type :unknown
			   :current-line (format nil "~a" form))))))

(vdefspecial %instance-struct (varjo-code)  
  (if (> (length varjo-code) 1)
      (error "Make-var cannot take more than one form")
      (let ((form (first varjo-code)))
	(make-instance 'code 
		       :type form
		       :current-line ""))))

(defun type-component-count (type-spec)
  (let* ((full-type (flesh-out-type type-spec))
	 (type (first full-type))
	 (length (assocr type *glsl-component-counts*)))
    (if length
	length
	(error "Type '~a' is not a vector or matrix componant type" type))))

(vdefspecial %init-vec-or-mat (varjo-code)
  (let* ((target-type (flesh-out-type (first varjo-code)))
	 (target-length (type-component-count target-type))
	 (arg-objs (mapcar #'varjo->glsl (rest varjo-code)))
	 (types (mapcar #'code-type arg-objs))
	 (lengths (mapcar #'type-component-count types)))
    (if (eq target-length (apply #'+ lengths))
	(make-instance 'code
		       :type target-type
		       :current-line 
		       (format nil "~a(~{~a~^,~^ ~})"
			       (varjo-type->glsl-type target-type)
			       (mapcar #'current-line arg-objs))
		       :to-block (mapcan #'to-block arg-objs)
		       :to-top (mapcan #'to-top arg-objs))
	(error "The lengths of the types provided~%(~{~a~^,~^ ~})~%do not add up to the length of ~a" types target-type))))

;; check for name clashes between forms
;; create init forms, for each one 

(vdefspecial let (varjo-code)
  (labels ((var-name (form) 
	     (if (listp (first form)) (first (first form))
		 (first form)))
	   (var-type (form) 
	     (when (listp (first form))
	       (flesh-out-type (second (first form)))))
	   (val (form) 
	     (second form))
	   (compile-form (name type value)
	     (varjo->glsl `(%typify (setf (%make-var (,name ,type))
					  ,value)))))
    (let* ((form-code (first varjo-code))
	   (body-code (rest varjo-code))	 
	   (val-objs (loop :for form in form-code
			   :collect (varjo->glsl (val form))))
	   (var-names (mapcar #'var-name form-code))
	   (var-gl-names (mapcar #'glsl-gensym var-names))
	   (var-types (loop :for form :in form-code
			    :for obj :in val-objs
			    :collect (or (var-type form)
					 (code-type obj))))
	   (form-objs (mapcar #'compile-form 
			      var-gl-names var-types val-objs))
	   (*glsl-variables*
	     (append (mapcar #'list 
			     var-names var-types var-gl-names)
		     *glsl-variables*)))
      (print form-code)
      (print var-gl-names)
      (print var-types)
      (print val-objs)
      (print form-objs)
      (let* ((prog-ob (funcall-special '%progn body-code)))
	(make-instance 'code
		       :type (code-type prog-ob)
		       :current-line (current-line prog-ob)
		       :to-block (append 
				  (mapcan #'to-block form-objs)
				  (mapcar #'current-line form-objs)
				  (to-block prog-ob))
		       :to-top (append 
				(mapcan #'to-top form-objs)
				(to-top prog-ob)))))))

(vdefspecial setf (varjo-code)  
  (if (> (length varjo-code) 2)
      (error "varjo setf can only set one var")
      (let* ((setf-form (mapcar #'varjo->glsl varjo-code))
	     (var (first setf-form))
	     (val (second setf-form))
	     (line (if (> (length (current-line val)) 0)
		       (format nil "~a = ~a"
			       (current-line var) 
			       (current-line val))
		       (format nil "~a" (current-line var))))
	     (type (if (equal (code-type var) (code-type val))
		       (code-type var)
		       (if (glsl-typep var '(:unknown nil nil))
			   (code-type val)
			   (error "Types of variable and value do not match~%~s ~s" (code-type var) (code-type val))))))
	(if (read-only var)
	    (error "Varjo: ~s is read only" (current-line var))
	    (make-instance 'code
			   :type type
			   :current-line line
			   :to-block (mapcan #'to-block setf-form)
			   :to-top (mapcan #'to-top setf-form))))))

(vdefspecial out (varjo-code)
  (let* ((arg-obj (varjo->glsl (second varjo-code)))
	 (out-var-name (first varjo-code))
	 (qualifiers (subseq varjo-code 2)))
    (if (assoc out-var-name *glsl-variables*)
	(error "The variable name '~a' is already taken and so cannot be used~%for an out variable" out-var-name)
	(make-instance 'code
		       :type :void
		       :current-line (format nil "~a = ~a;" 
					     out-var-name
					     (current-line arg-obj))
		       :to-block (to-block arg-obj)
		       :to-top (cons (format nil "~{~a ~}out ~a ~a;"
					     qualifiers
					     (varjo-type->glsl-type
					      (code-type arg-obj))
					     out-var-name)
				     (to-top arg-obj))))))

(vdefspecial + (varjo-code)    
  (let* ((arg-objs (mapcar #'varjo->glsl varjo-code))
	 (types (mapcar #'code-type arg-objs)))
    (if (apply #'types-compatiblep types)
	(make-instance 'code
		       :type (apply #'superior-type types)
		       :current-line (format nil "(~{~a~^ ~^+~^ ~})"
					     (mapcar #'current-line 
						     arg-objs))
		       :to-block (mapcan #'to-block arg-objs)
		       :to-top (mapcan #'to-top arg-objs))
	(error "The types of object passed to + are not compatible~%~{~s~^ ~}" types))))

(vdefspecial %- (varjo-code)    
  (let* ((arg-objs (mapcar #'varjo->glsl varjo-code))
	 (types (mapcar #'code-type arg-objs)))
    (if (apply #'types-compatiblep types)
	(make-instance 'code
		       :type (apply #'superior-type types)
		       :current-line (format nil "(~{~a~^ ~^-~^ ~})"
					     (mapcar #'current-line 
						     arg-objs))
		       :to-block (mapcan #'to-block arg-objs)
		       :to-top (mapcan #'to-top arg-objs))
	(error "The types of object passed to - are not compatible~%~{~s~^ ~}" types))))

(vdefspecial %/ (varjo-code)    
  (let* ((arg-objs (mapcar #'varjo->glsl varjo-code))
	 (types (mapcar #'code-type arg-objs)))
    (if (apply #'types-compatiblep types)
	(make-instance 'code
		       :type (apply #'superior-type types)
		       :current-line (format nil "(~{~a~^ ~^/~^ ~})"
					     (mapcar #'current-line 
						     arg-objs))
		       :to-block (mapcan #'to-block arg-objs)
		       :to-top (mapcan #'to-top arg-objs))
	(error "The types of object passed to - are not compatible~%~{~s~^ ~}" types))))

(vdefspecial %negate (varjo-code)  
  (if (> (length varjo-code) 1)
      (error "Negate cannot take more than one form")
      (let* ((arg-obj (varjo->glsl (first varjo-code))))
	(make-instance 'code
		       :type (code-type arg-obj)
		       :current-line (format nil "-~a"
					     (current-line arg-obj))
		       :to-block (to-block arg-obj)
		       :to-top (to-top arg-obj)))))


;;------------------------------------------------------------
;; Lisp Function Substitutions
;;-----------------------------

;; (vdefmacro + (&rest args)
;;   (oper-segment-list args '%+))

(vdefmacro - (&rest args)
  (if (eq 1 (length args))
      `(%negate ,@args)
      `(%- ,@args)))

(vdefmacro * (&rest args)
  (oper-segment-list args '*))

(vdefmacro / (&rest args)
  (oper-segment-list args '%/))

(vdefmacro v! (&rest args)
  `(%init-vec-or-mat ,(kwd (symb :vec (length args))) ,@args))

(vdefmacro vec2 (&rest args)
  `(%init-vec-or-mat :vec2 ,@args))

(vdefmacro vec3 (&rest args)
  `(%init-vec-or-mat :vec3 ,@args))

(vdefmacro vec4 (&rest args)
  `(%init-vec-or-mat :vec4 ,@args))

(vdefmacro ivec2 (&rest args)
  `(%init-vec-or-mat :ivec2 ,@args))

(vdefmacro ivec3 (&rest args)
  `(%init-vec-or-mat :ivec3 ,@args))

(vdefmacro ivec4 (&rest args)
  `(%init-vec-or-mat :ivec4 ,@args))

(vdefmacro uvec2 (&rest args)
  `(%init-vec-or-mat :uvec2 ,@args))

(vdefmacro uvec3 (&rest args)
  `(%init-vec-or-mat :uvec3 ,@args))

(vdefmacro uvec4 (&rest args)
  `(%init-vec-or-mat :uvec4 ,@args))

(vdefmacro mat2 (&rest args)
  `(%init-vec-or-mat :mat2 ,@args))

(vdefmacro mat3 (&rest args)
  `(%init-vec-or-mat :mat3 ,@args))

(vdefmacro mat4 (&rest args)
  `(%init-vec-or-mat :mat4 ,@args))

(vdefmacro mat2x2 (&rest args)
  `(%init-vec-or-mat :mat2x2 ,@args))

(vdefmacro mat2x3 (&rest args)
  `(%init-vec-or-mat :mat2x3 ,@args))

(vdefmacro mat2x4 (&rest args)
  `(%init-vec-or-mat :mat2x4 ,@args))

(vdefmacro mat3x2 (&rest args)
  `(%init-vec-or-mat :mat3x2 ,@args))

(vdefmacro mat3x3 (&rest args)
  `(%init-vec-or-mat :mat3x3 ,@args))

(vdefmacro mat3x4 (&rest args)
  `(%init-vec-or-mat :mat3x4 ,@args))

(vdefmacro mat4x2 (&rest args)
  `(%init-vec-or-mat :mat4x2 ,@args))

(vdefmacro mat4x3 (&rest args)
  `(%init-vec-or-mat :mat4x3 ,@args))

(vdefmacro mat4x4 (&rest args)
  `(%init-vec-or-mat :mat4x4 ,@args))
