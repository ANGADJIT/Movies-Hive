hdfs dfs -put data/movies.csv /data/movies.csv; # copy data from local to hdfs
hive -f scripts/movies.hql; # run movies script