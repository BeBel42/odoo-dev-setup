;; Some custom emacs settings for this specific project

;; Set project root to where .dir-locals.el is located
((nil .
  ((eval .
    (setq projectile-project-root
          (locate-dominating-file (or (buffer-file-name) default-directory) ".projectile"))))))
