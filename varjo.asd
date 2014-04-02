;;;; varjo.asd

(cl:defpackage :varjo-system
  (:use #:asdf #:cl))
(in-package :varjo-system)

(defclass varjo-source-file (cl-source-file)
  ())

(defvar +policy-fast+
  '((SPEED . 3) (SPACE . 1) (SAFETY . 0) (SB-EXT:INHIBIT-WARNINGS . 1) (DEBUG . 0) (COMPILATION-SPEED . 0)))
(defvar +policy-normal+
  '((SPEED . 1) (SPACE . 1) (SAFETY . 1) (SB-EXT:INHIBIT-WARNINGS . 1) (DEBUG . 1) (COMPILATION-SPEED . 1)))
(defvar +policy-debug+
  '((SPEED . 0) (SPACE . 1) (SAFETY . 3) (SB-EXT:INHIBIT-WARNINGS . 1) (DEBUG . 3) (COMPILATION-SPEED . 1)))
(defvar +policy-normal-cover+
  '((COMPILATION-SPEED . 1) (DEBUG . 1) (SB-EXT:INHIBIT-WARNINGS . 1) (SAFETY . 1)  (SPACE . 1) (SPEED . 1)
    (SB-C:STORE-COVERAGE-DATA . 3)))

(defvar *policy-current* +policy-debug+)

;; define policy/optimization settings for all files of the wurmatron ASDF system
#+sbcl
(defmethod perform :around ((o compile-op) (s varjo-source-file))
  (let ((SB-C::*POLICY* *policy-current*))
    (call-next-method)))

(asdf:defsystem #:varjo
  :default-component-class varjo-source-file
  :serial t
  :depends-on (#:cl-ppcre #:split-sequence)
  :components ((:file "package")
               (:file "utils-v")
               (:file "compiler/errors")
               (:file "language/types")
               (:file "compiler/types")
               (:file "compiler/variables")
               (:file "compiler/environment")
               (:file "compiler/structs")
               (:file "compiler/code-object")
               (:file "compiler/functions")
               (:file "language/variables")
               (:file "compiler/macros")
               (:file "language/macros")
               (:file "compiler/string-generation")
               (:file "compiler/compiler")
               (:file "language/special")
               (:file "language/functions")
               (:file "language/textures")
               (:file "compiler/front-end")))


