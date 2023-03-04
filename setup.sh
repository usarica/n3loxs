#!/bin/bash

(

set -euo pipefail

cd $(dirname ${BASH_SOURCE[0]})

GSL_VERSION=gsl-2.7.1

PKGDIR="$(readlink -f .)"
declare -i doPrintEnv=0
declare -i doPrintEnvInstr=0
declare -a setupArgs=()

for farg in "$@"; do
  fargl="$(echo $farg | awk '{print tolower($0)}')"
  if [[ "$fargl" == "env" ]]; then
    doPrintEnv=1
  elif [[ "$fargl" == "envinstr" ]]; then
    doPrintEnvInstr=1
  else
    setupArgs+=( "$farg" ) 
  fi
done
declare -i nSetupArgs
nSetupArgs=${#setupArgs[@]}

extpkg_maindir=${PKGDIR}/..
extpkgdir=${extpkg_maindir}/external

gsl_path=${extpkg_maindir}/gsl_install

setupenv(){
  iPrint=$1

  libappend="${gsl_path}/lib"
  end=""
  if [[ ! -z "${LD_LIBRARY_PATH+x}" ]]; then
    end=":${LD_LIBRARY_PATH}"
  fi
  if [[ "${end}" != *"$libappend"* ]]; then
    if [[ ${iPrint} -eq 1 ]]; then
      echo "export LD_LIBRARY_PATH=${libappend}${end}"
    fi
    export LD_LIBRARY_PATH=${libappend}${end}
  fi

  libappend=$(lhapdf-config --libdir)
  end=""
  if [[ ! -z "${LD_LIBRARY_PATH+x}" ]]; then
    end=":${LD_LIBRARY_PATH}"
  fi
  if [[ "${end}" != *"$libappend"* ]]; then
    if [[ ${iPrint} -eq 1 ]]; then
      echo "export LD_LIBRARY_PATH=${libappend}${end}"
    fi
    export LD_LIBRARY_PATH=${libappend}${end}
  fi
}
printenvinstr () {
  echo
  echo "to use this repo, you must run:"
  echo
  echo 'eval $('${BASH_SOURCE[0]}' env)'
  echo "or"
  echo 'eval `'${BASH_SOURCE[0]}' env`'
  echo
  echo "if you are using a bash-related shell, or you can do"
  echo
  echo ${BASH_SOURCE[0]}' env'
  echo
  echo "and change the commands according to your shell in order to do something equivalent to set up the environment variables."
  echo
}

if [[ $doPrintEnv -eq 1 ]]; then
    setupenv 1
    exit
elif [[ $doPrintEnvInstr -eq 1 ]]; then
    printenvinstr
    exit
fi

if [[ $nSetupArgs -eq 0 ]]; then
    setupArgs+=( -j 1 )
    nSetupArgs=2
fi


if [[ "$nSetupArgs" -eq 1 ]] && [[ "${setupArgs[0]}" == *"clean"* ]]; then
    make clean

    exit $?
elif [[ "$nSetupArgs" -ge 1 ]] && [[ "$nSetupArgs" -le 2 ]] && [[ "${setupArgs[0]}" == *"-j"* ]]; then
    : ok
else
    echo "Unknown arguments:"
    echo "  ${setupArgs[@]}"
    echo "Should be nothing, env, envinstr, clean, or -j [Ncores]"
    exit 1
fi


if [[ ! -d ${gsl_path} ]] && [[ -d ${extpkgdir} ]]; then
  cp ${extpkgdir}/${GSL_VERSION}.tar.gz ${extpkg_maindir}
  (
  cd ${extpkg_maindir}
  tar xf ${GSL_VERSION}.tar.gz
  cd ${GSL_VERSION}
  ./configure --prefix=${gsl_path} && make && make install
  cd ${PKGDIR}
  )
fi
if [[ ! -d ${gsl_path} ]]; then
  echo "Could not find the gsl installation path. Exiting..."
  exit 1
fi

setupenv 0

# Compile this repository
make GSL_INSTALL_PREFIX=${gsl_path} "${setupArgs[@]}"
compile_status=$?
if [[ ${compile_status} -ne 0 ]]; then
  echo "Compilation failed with status ${compile_status}."
  exit ${compile_status}
fi

printenvinstr

)
