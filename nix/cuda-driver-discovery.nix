''
  _mineru_cuda_driver_candidates=()
  if [ -n "''${LD_LIBRARY_PATH:-}" ]; then
    _mineru_old_ifs="$IFS"
    IFS=:
    for _mineru_dir in $LD_LIBRARY_PATH; do
      if [ -n "$_mineru_dir" ]; then
        _mineru_cuda_driver_candidates+=("$_mineru_dir")
      fi
    done
    IFS="$_mineru_old_ifs"
  fi
  _mineru_cuda_driver_candidates+=(
    /run/opengl-driver/lib
    /usr/lib/wsl/lib
    /usr/lib/x86_64-linux-gnu
    /usr/lib64
    /usr/lib
  )

  _mineru_cuda_driver_dirs=
  _mineru_first_cuda_driver_dir=
  for _mineru_dir in "''${_mineru_cuda_driver_candidates[@]}"; do
    if [ -d "$_mineru_dir" ] \
       && { [ -e "$_mineru_dir/libcuda.so.1" ] || [ -e "$_mineru_dir/libcuda.so" ]; }; then
      case ":$_mineru_cuda_driver_dirs:" in
        *":$_mineru_dir:"*) ;;
        *)
          _mineru_cuda_driver_dirs="''${_mineru_cuda_driver_dirs:+$_mineru_cuda_driver_dirs:}$_mineru_dir"
          if [ -z "$_mineru_first_cuda_driver_dir" ]; then
            _mineru_first_cuda_driver_dir="$_mineru_dir"
          fi
          ;;
      esac
    fi
  done

  export MINERU_CUDA_DRIVER_DIRS="$_mineru_cuda_driver_dirs"
  export MINERU_CUDA_DRIVER_DIR="$_mineru_first_cuda_driver_dir"
  if [ -n "$_mineru_cuda_driver_dirs" ]; then
    export LD_LIBRARY_PATH="$_mineru_cuda_driver_dirs:''${LD_LIBRARY_PATH:-}"
    export LIBRARY_PATH="$_mineru_cuda_driver_dirs:''${LIBRARY_PATH:-}"
    export TRITON_LIBCUDA_PATH="$_mineru_first_cuda_driver_dir"
  fi
''
