;;; whisper.el --- Speech-to-Text interface using OpenAI's whisper model -*- lexical-binding: t; -*-

;; INSTALL
;; Required to build (ONE TIME ONLY!)
;; > sudo apt update && sudo apt install cmake build-essential -y
;; Required to run every time.
;; > sudo apt update && sudo apt install ffmpeg -y

;; Speech-to-Text
;; TODO: https://sachachua.com/blog/2026/01/using-whisper-el-to-capture-text-to-speech-in-emacs/

(use-package whisper
  :vc (:url "https://github.com/natrys/whisper.el" :branch "master")
  :config
  (setq whisper--mode-line-recording-indicator "⏺")
  (setq whisper-install-whispercpp "manual")
  (setq whisper-quantize "q4_0")
  (setq whisper-install-directory "~/.emacs.d/.cache")
  (setq whisper--install-path (concat
                               (expand-file-name (file-name-as-directory whisper-install-directory))
                               "whisper.cpp/"))
  (setq whisper-return-cursor-to-start nil)
  (setq whisper--ffmpeg-input-device "qubes-source")
  (setq whisper-language "en")
  (setq whisper-recording-timeout 3000)
  (setq whisper-before-transcription-hook nil)
  (setq whisper-use-threads (/ (num-processors) 2))
  ;;(setq whisper-use-threads (1- (num-processors)))
  (setq whisper-transcription-buffer-name-function 'whisper--simple-transcription-buffer-name)
  :bind
  (("<f9>" . whisper-run)
   ("M-<f9>" . whisper-run)
   ("C-<f9>" . whisper-run)))


(defun my-whisper-install-cpp (&optional model quant)
  "Clone, build, download, and quantize whisper.cpp in ~/.emacs.d/.cache/.
MODEL defaults to \"small.en\" and QUANT defaults to \"q4_0\".
Skips execution if the final quantized model already exists."
  (interactive
   (list (read-string "Whisper model (default small.en): " nil nil "small.en")
         (read-string "Quantization type (default q4_0): " nil nil "q4_0")))
  (let* ((model (or model "small.en"))
         (quant (or quant "q4_0"))
         (cache-dir (expand-file-name ".cache" user-emacs-directory))
         (final-model (expand-file-name
                       (format "whisper.cpp/models/ggml-%s-%s.bin" model quant)
                       cache-dir)))
    (if (file-exists-p final-model)
        (message "Quantized model already exists at %s; skipping." final-model)
      (let* ((q-model (shell-quote-argument model))
             (q-quant (shell-quote-argument quant))
             (default-directory cache-dir)
             (cmd (string-join
                   (list "sudo apt update"
                         "sudo apt install cmake build-essential -y"
                         "git clone https://github.com/ggml-org/whisper.cpp"
                         "cd whisper.cpp"
                         "cmake -B build"
                         "cmake --build build --config Release -j"
                         (format "./models/download-ggml-model.sh %s" q-model)
                         (format "./build/bin/whisper-quantize models/ggml-%s.bin ./models/ggml-%s-%s.bin %s"
                                 q-model q-model q-quant q-quant))
                   " && ")))
        (make-directory cache-dir t)
        (compilation-start cmd 'compilation-mode (lambda (_) "*whisper.cpp-install*"))))))
