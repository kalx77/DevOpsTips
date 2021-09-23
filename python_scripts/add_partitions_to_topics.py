# Need kafka-python package
from kafka import KafkaAdminClient
from kafka import KafkaConsumer
from kafka.admin import NewPartitions
import re

bootstrap_servers = "kafka-customers-c-1-v1.corp.itcd.ru"
topic_pattern = ".*CDP.Scenarios.Runtime"
need_partitions = 4

admin_client = KafkaAdminClient(
  bootstrap_servers = bootstrap_servers
)

consumer = KafkaConsumer(
  group_id='test',
  bootstrap_servers = bootstrap_servers
)

topics = consumer.topics()
cdp_topics = [topic for topic in consumer.topics() if re.match(topic_pattern, topic)]

for topic in cdp_topics:
  partitions = len(consumer.partitions_for_topic(topic))
  if partitions < need_partitions:
    print(f'Increase number of partitions in topic {topic} to {need_partitions}')
    # topic_partitions = {}
    # topic_partitions[topic] = NewPartitions(total_count=need_partitions)
    # admin_client.create_partitions(topic_partitions)

consumer.close()
admin_client.close()
