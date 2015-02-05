import boto
import boto.s3.connection

connection = boto.connect_s3(
    aws_access_key_id='SLOS393306-2:raghon',
    aws_secret_access_key='acc4db2b872d48d46c61fac1395ebbcd67956d9f2fc358c38f29dc80efba5f2a',
    port=443,
    host='ams01.objectstorage.service.networklayer.com',
    is_secure=True,
    validate_certs=False,
    calling_format=boto.s3.connection.OrdinaryCallingFormat())
connection.create_bucket('seafile-commits')
#connection.create_bucket('seafile-fs')
#connection.create_bucket('seafile-blocks')
