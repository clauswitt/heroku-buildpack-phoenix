# Outputs log line
#
# Usage:
#
#     output_line "Cloning repository"
#
function output_line() {
  local spacing="      "
  echo "${spacing} $1"
}

# Outputs section heading
#
# Usage:
#
#     output_section "Application tasks"
#
function output_section() {
  local indentation="----->"
  echo "${indentation} $1"
}

info() {
  #echo "`date +\"%M:%S\"`  $*"
  echo "       $*"
}

indent() {
  c='s/^/       /'
  case $(uname) in
    Darwin) sed -l "$c";; # mac/bsd sed: -l buffers on line boundaries
    *)      sed -u "$c";; # unix/gnu sed: -u unbuffered (arbitrary) chunks of data
  esac
}

head() {
  echo ""
  echo "-----> $*"
}

file_contents() {
  if test -f $1; then
    echo "$(cat $1)"
  else
    echo ""
  fi
}

function load_config() {
  output_section "Loading configuration..."

  local custom_config_file="${build_path}/phoenix_buildpack.config"

  # Source for default versions file from buildpack first
  source "${build_pack_path}/phoenix_buildpack.config"

  if [ -f $custom_config_file ];
  then
    source $custom_config_file
  else
    output_line "WARNING: elixir_buildpack.config wasn't found in the app"
    output_line "Using default config from Elixir buildpack"
  fi

  output_line "Will use the following versions:"
  output_line "* Stack ${STACK}"
  output_line "* Erlang ${erlang_version}"
  output_line "* Elixir ${elixir_version[0]} ${elixir_version[1]}"
  output_line "Will export the following config vars:"
  output_line "* Config vars ${config_vars_to_export[*]}"
}


# Make the config vars from config_vars_to_export available at slug compile time.
# Useful for compiled languages like Erlang and Elixir
function export_config_vars() {
  for config_var in ${config_vars_to_export[@]}; do
    if [ -d $env_path ] && [ -f $env_path/${config_var} ]; then
      export ${config_var}=$(cat $env_path/${config_var})
    fi
  done
}

function export_mix_env() {
  if [ -d $env_path ] && [ -f $env_path/MIX_ENV ]; then
    export MIX_ENV=$(cat $env_path/MIX_ENV)
  else
    export MIX_ENV=prod
  fi

  output_line "* MIX_ENV=${MIX_ENV}"
}

function check_stack() {
  if [ "${STACK}" = "cedar" ]; then
    echo "ERROR: cedar stack is not supported, upgrade to cedar-14"
    exit 1
  fi

  if [ ! -f "${cache_path}/stack" ] || [ $(cat "${cache_path}/stack") != "${STACK}" ]; then
    output_section "Stack changed, will rebuild"
    rm -rf ${cache_path}/*
  fi

  echo "${STACK}" > "${cache_path}/stack"
}

function clean_cache() {
  if [ $always_rebuild = true ]; then
    output_section "Cleaning all cache to force rebuilds"
    rm -rf $cache_path/*
  fi
}
