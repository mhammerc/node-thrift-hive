
assert = require 'assert'
hive = require "#{__dirname}/.."

db = 'test_database'
table = 'test_table'

client = hive.createClient
    version: '0.7.1-cdh3u2'
    server: '127.0.0.1'
    port: 10000
    timeout: 1000

module.exports =
    'Prepare': (next) ->
        client.execute "CREATE DATABASE IF NOT EXISTS #{db}", (err) ->
            assert.ifError err
            client.execute "USE #{db}", (err) ->
                assert.ifError err
                client.execute """
                    CREATE TABLE IF NOT EXISTS #{table} ( 
                        a_bigint BIGINT,
                        an_int INT,
                        a_date STRING
                    )
                    ROW FORMAT DELIMITED
                    FIELDS TERMINATED BY ','
                """, (err) ->
                    assert.ifError err
                    client.execute """
                    LOAD DATA LOCAL INPATH '#{__dirname}/data.csv' OVERWRITE INTO TABLE #{table}
                    """, (err) ->
                        assert.ifError err
                        next()
    'Query # all': (next) ->
        count = 0
        client.query("SELECT * FROM #{table}")
        .on 'row', (row) ->
            count++
            assert.ok Array.isArray row
            assert.eql row.length, 3
        .on 'error', (err) ->
            assert.ok false
        .on 'end', ->
            assert.eql count, 54
            next()
    'Query # n': (next) ->
        count = 0
        client.query("select * from #{table}", 10)
        .on 'row', (row) ->
            count++
        .on 'error', (err) ->
            assert.ok false
        .on 'end', ->
            assert.eql count, 54
            next()
    'Query # error': (next) ->
        client.query("select * from undefined_table", 10)
        .on 'row', (row) ->
            assert.ok false
        .on 'error', (err) ->
            assert.ok err instanceof Error
            next()
        .on 'end', ->
            assert.ok false
    'Query # pause/resume': (next) ->
        count = 0
        query = client.query("select * from #{table}", 10)
        .on 'row', (row) ->
            count++
            query.pause()
            setTimeout ->
                query.resume()
            , 10
        .on 'error', (err) ->
            assert.ok false
        .on 'end', ->
            assert.eql count, 54
            next()
    'Close': (next) ->
        client.end()
        next()