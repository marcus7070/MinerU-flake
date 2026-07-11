''
  _mineru_rocm_driver_candidates=()
  if [ -n "''${LD_LIBRARY_PATH:-}" ]; then
    _mineru_old_ifs="$IFS"
    IFS=:
    for _mineru_dir in $LD_LIBRARY_PATH; do
      if [ -n "$_mineru_dir" ]; then
        _mineru_rocm_driver_candidates+=("$_mineru_dir")
      fi
    done
    IFS="$_mineru_old_ifs"
  fi
  _mineru_rocm_driver_candidates+=(
    /run/opengl-driver/lib
    /opt/rocm/lib
    /usr/lib/x86_64-linux-gnu
    /usr/lib64
  )

  _mineru_rocm_driver_dirs=
  _mineru_first_rocm_driver_dir=
  for _mineru_dir in "''${_mineru_rocm_driver_candidates[@]}"; do
    if [ -d "$_mineru_dir" ] \
       && { [ -e "$_mineru_dir/libamdhip64.so" ] || [ -e "$_mineru_dir/libamdhip64.so.5" ]; }; then
      case ":$_mineru_rocm_driver_dirs:" in
        *":$_mineru_dir:"*) ;;
        *)
          _mineru_rocm_driver_dirs="''${_mineru_rocm_driver_dirs:+$_mineru_rocm_driver_dirs:}$_mineru_dir"
          if [ -z "$_mineru_first_rocm_driver_dir" ]; then
            _mineru_first_rocm_driver_dir="$_mineru_dir"
          fi
          ;;
      esac
    fi
  done

  export MINERU_ROCM_DRIVER_DIRS="$_mineru_rocm_driver_dirs"
  export MINERU_ROCM_DRIVER_DIR="$_mineru_first_rocm_driver_dir"
  if [ -n "$_mineru_rocm_driver_dirs" ]; then
    export LD_LIBRARY_PATH="$_mineru_rocm_driver_dirs:''${LD_LIBRARY_PATH:-}"
  fi
  export HSA_OVERRIDE_GFX_VERSION="''${HSA_OVERRIDE_GFX_VERSION:-10.3.0}"
''
