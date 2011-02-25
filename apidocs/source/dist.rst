Distribution API
================

http://frepan.org/api/v1/dist/show.json
---------------------------------------

HTTP Method
~~~~~~~~~~~

GET

Parameters
~~~~~~~~~~

:dist_name: Distribution Name(required)
:dist_version: Distribution version. If you don't specified this parameter, FrePAN API use latest version.

Return Values
~~~~~~~~~~~~~

http://frepan.org/api/v1/dist/show.json?dist_name=I18N-Handle

.. literalinclude:: response/dist_show.json

