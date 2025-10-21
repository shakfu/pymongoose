Installation
============

Requirements
------------

- Python 3.9 or higher
- C compiler (gcc, clang, or MSVC)
- CMake (optional, for alternative build method)

Dependencies
~~~~~~~~~~~~

pymongoose has minimal dependencies:

- **Cython** (>=3.0) - Used for building the extension
- **setuptools** - Build system

Optional dependencies for development:

- **pytest** - Running tests
- **websocket-client** - WebSocket client tests
- **aiohttp, fastapi, uvicorn, flask** - Benchmark comparisons

Install from PyPI
-----------------

The easiest way to install pymongoose is from PyPI:

.. code-block:: bash

    pip install pymongoose

This will download and install the latest stable release along with all required dependencies.

Install from Source
-------------------

Using pip
~~~~~~~~~

To install the latest development version from the repository:

.. code-block:: bash

    git clone https://github.com/your-username/pymongoose.git
    cd pymongoose
    pip install -e .

Using uv (Recommended for Development)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

`uv <https://github.com/astral-sh/uv>`_ is a fast Python package installer and resolver:

.. code-block:: bash

    git clone https://github.com/your-username/pymongoose.git
    cd pymongoose
    uv sync

This will:

1. Create a virtual environment
2. Install all dependencies
3. Build the Cython extension
4. Install pymongoose in editable mode

Using CMake (Alternative)
~~~~~~~~~~~~~~~~~~~~~~~~~

For advanced users who prefer CMake:

.. code-block:: bash

    git clone https://github.com/your-username/pymongoose.git
    cd pymongoose
    make build

Build Options
~~~~~~~~~~~~~

You can customize the build with environment variables:

.. code-block:: bash

    # Build universal binary on macOS (Intel + ARM)
    UNIVERSAL=1 pip install -e .

    # Build debug version
    CONFIG=Debug make build

    # Disable TLS support
    USE_TLS=0 pip install -e .

    # Disable nogil optimization
    USE_NOGIL=0 pip install -e .

Verifying Installation
----------------------

After installation, verify it works:

.. code-block:: python

    import pymongoose
    print(pymongoose.__version__)

    # Check available constants
    from pymongoose import (
        Manager,
        Connection,
        MG_EV_HTTP_MSG,
        MG_EV_WS_MSG,
        WEBSOCKET_OP_TEXT,
    )
    print("Installation successful!")

Running Tests
-------------

To run the test suite:

.. code-block:: bash

    # Using make
    make test

    # Using pytest directly
    PYTHONPATH=src pytest tests/ -v

All 210 tests should pass. If you encounter failures, please report them on the `issue tracker <https://github.com/your-username/pymongoose/issues>`_.

Troubleshooting
---------------

Build Errors
~~~~~~~~~~~~

**Error: "Cython not found"**

Install Cython:

.. code-block:: bash

    pip install cython

**Error: "C compiler not found"**

Install a C compiler:

- **Linux**: ``sudo apt-get install build-essential``
- **macOS**: ``xcode-select --install``
- **Windows**: Install Visual Studio with C++ tools

**Error: "mongoose.h not found"**

The Mongoose library is vendored in ``thirdparty/mongoose/``. Ensure you've cloned the repository completely:

.. code-block:: bash

    git clone --recursive https://github.com/your-username/pymongoose.git

Import Errors
~~~~~~~~~~~~~

**Error: "ImportError: cannot import name 'Manager'"**

This usually means the extension wasn't built. Try:

.. code-block:: bash

    pip install -e . --force-reinstall

**Error: "Symbol not found" or "DLL load failed" on macOS**

Rebuild with:

.. code-block:: bash

    pip uninstall pymongoose
    pip install -e . --no-cache-dir

Performance Issues
~~~~~~~~~~~~~~~~~~

If performance is lower than expected:

1. Verify nogil is enabled (check startup message)
2. Ensure you're using ``poll(100)`` not ``poll(5000)``
3. Check if TLS is needed - disable if not: ``USE_TLS=0 pip install -e .``

For more help, see the :doc:`advanced/troubleshooting` guide.

Next Steps
----------

- Follow the :doc:`quickstart` guide to build your first application
- Browse :doc:`examples` for common use cases
- Read the :doc:`guide/index` for protocol-specific documentation
