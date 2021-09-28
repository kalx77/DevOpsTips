# Need kafka-python package
from time import sleep
from kafka import KafkaAdminClient
from kafka import KafkaConsumer
from kafka.admin import NewPartitions
import re

bootstrap_servers = "kafka-customers-c-1-v1.corp.itcd.ru"
topic_pattern = ".*CDP.Scenarios.Runtime"
need_partitions = 4
sleep_after = 20
sleeping_time = 20

admin_client = KafkaAdminClient(
  bootstrap_servers = bootstrap_servers
)

consumer = KafkaConsumer(
  group_id='test',
  bootstrap_servers = bootstrap_servers
)

topics = consumer.topics()
cdp_topics = [topic for topic in consumer.topics() if re.match(topic_pattern, topic)]
topics_amount = len(cdp_topics)
counter = 0

for topic in cdp_topics:
  partitions = len(consumer.partitions_for_topic(topic))
  if partitions < need_partitions:
    print(f'Increase number of partitions in topic {topic} to {need_partitions}')
    counter += 1
    topic_partitions = {}
    topic_partitions[topic] = NewPartitions(total_count=need_partitions)
    admin_client.create_partitions(topic_partitions)

    if counter % sleep_after == 0 and counter != 0 and counter <= topics_amount:
      print(f"Sleeping {sleeping_time} seconds")
      sleep(sleeping_time)

print(f"All of {counter} from {topics_amount} topics upgraded!")

consumer.close()
admin_client.close()
