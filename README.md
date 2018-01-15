This application helps to generate an API. Follow these steps:

1. create a database schema with MySQL workbench
1. run the `rapid_api` command

The defaults do not fit my needs
================================

If you want to use an other database than SQLite, or you do not need a [Mojolicious](http://mojolicious.org)
application as you usually use [Dancer](http://perldancer.org/) you can do one or more of the following steps:

1. create a database schema with MySQL workbench
1. create DBIx::Class schema from workbench model
1. create Database based on the DBIx::Class schema
1. generate Swagger spec for the database
1. create Mojolicious app that provides the API

Create a database schema with MySQL workbench
---------------------------------------------



Create DBIx::Class schema from workbench model
----------------------------------------------

Create database based on the DBIx::Class schema
-----------------------------------------------

Generate Swagger spec for the database
--------------------------------------

Create Mojolicious app
----------------------
