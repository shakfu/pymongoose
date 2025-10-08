import sys
import os
import warnings
from setuptools import setup, Extension

# Try to import Cython
try:
    from Cython.Build import cythonize
    HAVE_CYTHON = True
except ImportError:
    HAVE_CYTHON = False
    warnings.warn(
        "Cython not found. Installing without optimized extensions. "
        "For better performance, install Cython and rebuild: "
        "pip install Cython && pip install --no-build-isolation -e .",
        UserWarning
    )


def build_extensions():
    """Build Cython extension modules."""
    if not HAVE_CYTHON:
        return []

    # Compiler flags
    extra_compile_args = []
    extra_link_args = []

    # TLS configuration
    # MG_TLS_BUILTIN enables built-in TLS (no external deps)
    # MG_TLS_NONE disables TLS but allows nogil optimization
    use_tls = False  # Change to False to disable TLS and enable nogil

    if use_tls:
        define_macros = [
            ("MG_TLS", "MG_TLS_BUILTIN"),  # Enable built-in TLS support
            ("MG_ENABLE_PACKED_FS", "0"),  # Disable packed filesystem (not needed)
            # ("USE_NOGIL", "0"),            # Disable nogil (TLS uses internal locks)
        ]
    else:
        define_macros = [
            ("MG_TLS", "MG_TLS_NONE"),     # Disable TLS
            ("MG_ENABLE_PACKED_FS", "0"),  # Disable packed filesystem (not needed)
            # ("USE_NOGIL", "1"),            # Enable nogil for parallel execution
        ]

    if sys.platform == "darwin":
        # macOS specific flags
        extra_compile_args.extend(["-O3", "-std=c99"])
    elif sys.platform == "linux":
        # Linux specific flags
        extra_compile_args.extend(["-O3", "-std=c99"])
    elif sys.platform == "win32":
        # Windows specific flags
        extra_compile_args.extend(["/O2"])

    include_dirs = ["thirdparty/mongoose"]

    extensions = [
        Extension(
            "pymongoose._mongoose",
            sources=[
                "src/pymongoose/_mongoose.pyx",
                "thirdparty/mongoose/mongoose.c",
            ],
            include_dirs=include_dirs,
            define_macros=define_macros,
            extra_compile_args=extra_compile_args,
            extra_link_args=extra_link_args,
        ),
    ]

    # Cythonize with compiler directives
    return cythonize(
        extensions,
        compiler_directives={
            "language_level": "3",
            "boundscheck": False,
            "wraparound": False,
            "cdivision": True,
            "embedsignature": True,
        },
        # compile_time_env={
        #     "USE_NOGIL": not use_tls,
        # },
        # Build in parallel if possible
        nthreads=os.cpu_count() or 1,
    )


# Only build extensions if Cython is available
ext_modules = build_extensions()

# Let setuptools handle the rest via pyproject.toml
setup(
    ext_modules=ext_modules,
    package_dir={"": "src"},
)
