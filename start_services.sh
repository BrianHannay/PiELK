#!/bin/bash -v
/elasticsearch-7.8.0/bin/elasticsearch &
sleep 5m;
LD_LIBRARY_PATH=/usr/local/lib/ /kibana-7.8.0-linux-x86_64/bin/kibana --allow-root &
sleep 5m;
until curl -s localhost:9200 | grep "minimum_index_compatibility_version"; do
	sleep 5;
done

echo "Checking if initialization required...";
if curl localhost:9200/octobot_portfolio | grep "index_not_found_exception"; then
	echo "Initializing elasticsearch";
	curl -H 'Content-Type: application/json' -v -X PUT localhost:9200/octobot_portfolio -d '
	{
		"settings": {
			"number_of_shards": 1
		},
		"mappings": {
			"properties": {
				"portfolio_value_btc": { 		       
					"type": "scaled_float",
					"scaling_factor": 100000000
				}
			}
		}
	}
	';
	sleep 1;
	curl -X PUT -H 'Content-Type: application/json' localhost:9200/_ingest/pipeline/indexed_at -d '
	{
		"description": "Adds indexed_at timestamp to documents",
		"processors": [
			{
				"set": {
					"field": "_source.indexed_at",
					"value": "{{_ingest.timestamp}}"
				}
			}
		]
	}
	'

fi
echo "Starting portfolio logger update loop";
while :; do

	value="$(curl octobot:5001/portfolio | grep 'Real portfolio: [^ ]\+ BTC' | grep -o '[0-9]\+\.[0-9]\+')"
	if [[ "$value" != "" ]]; then 
		echo "Posting portfolio value: $value";
		curl -s -H 'Content-Type: application/json' -XPOST localhost:9200/octobot_portfolio/_doc -d '{"portfolio_value_btc":'"$value"'}'
		sleep 300
	fi;
done &
sleep 5m;
/logstash-7.8.0/bin/logstash -f /logstash-7.8.0/config/logstash.yml
