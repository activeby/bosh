# Copyright (c) 2003-2012 Active Cloud, Inc.

Sequel.migration do
  change do
    create_table :cloudstack_servers do
      primary_key :id

      String :server_id, :null => false, :unique => true
      String :settings, :null => false, :text => true
    end
  end
end