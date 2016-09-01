#!/bin/sh


export SRC_DIR="/tmp/SimpleITK"
export BLD_DIR="/tmp/SimpleITK-build"
export OUT_DIR="/var/io"


function build_simpleitk {
    
    NPROC=$(cat /proc/cpuinfo | grep processor | wc -l)

    git clone https://itk.org/SimpleITK.git ${SRC_DIR} &&
    (cd ${SRC_DIR}  && git checkout v0.10.0 ) &&
    (cd ${SRC_DIR}  && git checkout cf5c9eb -- ./SimpleITKConfig.cmake.in ) &&
    rm -rf ${BLD_DIR} &&
    mkdir -p ${BLD_DIR} && cd ${BLD_DIR} &&
    cmake \
        -DSimpleITK_BUILD_DISTRIBUTE:BOOL=ON \
        -DSimpleITK_BUILD_STRIP:BOOL=ON \
        -DCMAKE_BUILD_TYPE:STRING=Release \
        -DBUILD_TESTING:BOOL=ON \
        -DBUILD_SHARED_LIBS:BOOL=OFF \
        -DWRAP_CSHARP:BOOL=OFF \
        -DWRAP_LUA:BOOL=OFF\
        -DWRAP_PYTHON:BOOL=OFF \
        -DWRAP_JAVA:BOOL=OFF \
        -DWRAP_TCL:BOOL=OFF \
        -DWRAP_R:BOOL=OFF \
        -DWRAP_RUBY:BOOL=OFF \
        ${SRC_DIR}/SuperBuild &&
    make -j ${NPROC} && \
    find ./ -name \*.o -delete
}




function build_simpleitk_python {
    
    NPROC=$(cat /proc/cpuinfo | grep processor | wc -l)

    rm -rf ${BLD_DIR}-${PYTHON} &&
    mkdir -p ${BLD_DIR}-${PYTHON} &&
    cd ${BLD_DIR}-${PYTHON} &&
    cmake \
        -D "CMAKE_CXX_FLAGS:STRING=-fvisibility=hidden -fvisibility-inlines-hidden ${CFLAGS}" \
        -D "CMAKE_C_FLAGS:STRING=-fvisibility=hidden ${CXXFLAGS}" \
        -DCMAKE_MODULE_PATH:PATH=${SRC_DIR} \
        -DSimpleITK_DIR:PATH=${BLD_DIR}/SimpleITK-build \
        -DSWIG_EXECUTABLE:FILEPATH=${BLD_DIR}/Swig/bin/swig \
        -DSWIG_DIR:PATH=${BLD_DIR}/Swig/ \
        -DSimpleITK_BUILD_DISTRIBUTE:BOOL=ON \
        -DSimpleITK_BUILD_STRIP:BOOL=ON \
        -DCMAKE_BUILD_TYPE:STRING=Release \
        -DSimpleITK_PYTHON_WHEEL:BOOL=ON \
        -DSimpleITK_PYTHON_EGG:BOOL=OFF \
        -DPYTHON_EXECUTABLE:FILEPATH=/opt/python/${PYTHON}/bin/python \
        -DPYTHON_INCLUDE_DIR:PATH=$( find -L /opt/python/${PYTHON}/include/ -name Python.h -exec dirname {} \; ) \
        -DPYTHON_LIBRARY:FILEPATH=$( find -L /opt/python/${PYTHON}/lib -name libpython\*.a ) \
        -DPYTHON_VIRTUALENV_SCRIPT:FILEPATH=${BLD_DIR}/virtualenv/virtualenv.py \
        ${SRC_DIR}/Wrapping/Python &&
    make -j ${NPROC} &&
    make dist

}

build_simpleitk || exit 1

PYTHON_VERSIONS="cp27-cp27m cp27-cp27mu  cp33-cp33m  cp34-cp34m  cp35-cp35m"

for PYTHON in ${PYTHON_VERSIONS}; do
    build_simpleitk_python &&
    ctest -j ${NPROC} && 
    auditwheel repair $(find ${BLD_DIR}-${PYTHON}/ -name SimpleITK*.whl) -w /var/io/wheelhouse/
done




 
