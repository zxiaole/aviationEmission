import paramiko
from pathlib import Path
import hashlib
import calendar
import datetime
import pyarrow as pa
import pandas as pd
import pyarrow.parquet as pq

myUsername = 'Fill in your username'
myPassword = 'Fill in your password'
connected = False
cache_dir = Path('/data/database/Openskynet/opensky/cache_zurich')
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

# connect opensky database
client.connect('data.opensky-network.org', port=2230, username=myUsername, password=myPassword, look_for_keys=False,allow_agent=False,compress=True,)
stdin, stdout, stderr = client.exec_command("-B", bufsize=-1, get_pty=True)
total = ""
while len(total) == 0 or total[-10:] != ":21000] > ":
    b = stdout.channel.recv(256)
    total += b.decode()

print('Connected Successfully ...')

# Zurich Airport domain
latll = 47.395075
lonll = 8.482907
latur = 47.532957
lonur = 8.641831

# Time
yearStart = 2019
monthStart = 2
dayStart = 1
hourStart = 0

####
def getUnixTimeStamp(currentDate, timeZone):
	timeStamp = int(currentDate.timestamp() - timeZone*3600)
	return timeStamp
###
def getLATimeZone(currentDate):
# how to work with date
# Summer time in Zurich begins at the last sunday in March, ends at the last sunday in Octobor
	year = currentDate.year
	summerTimeStartDay = 31 + (6 - calendar.weekday(year, 3, 31))
	if(summerTimeStartDay>31):
		summerTimeStartDay = summerTimeStartDay - 7
	summerTimeStart = datetime.datetime(year, 3, summerTimeStartDay, 3, 0)
	
	summerTimeEndDay = 31 + (6 - calendar.weekday(year, 10, 31))
	if(summerTimeEndDay>31):
		summerTimeEndDay = summerTimeEndDay - 7
	summerTimeEnd = datetime.datetime(year, 10, summerTimeEndDay, 2, 0)

	if(currentDate>=summerTimeStart and currentDate<=summerTimeEnd):
		timeZone = 2
	else:
		timeZone = 1
	return timeZone
###
def genFileName(sDate, eDate):
	fname = sDate.strftime("%Y%m%d%H")+'To'+eDate.strftime("%Y%m%d%H")
	return fname


startDate =  datetime.datetime(yearStart, monthStart, dayStart, hourStart, 0)
for month in range(0,52):
	endDate =  startDate + datetime.timedelta(days=7)
	

	startTimeStamp = getUnixTimeStamp(startDate, getLATimeZone(startDate))
	endTimeStamp = getUnixTimeStamp(endDate, getLATimeZone(endDate))

	request = 'SELECT * from state_vectors_data4 where lat<' + str(latur) + ' and lat>' + str(latll) + ' and lon<' +str(lonur) + ' and lon>' + str(lonll) + ' and hour>='  + str(startTimeStamp) + ' and hour<=' + str(endTimeStamp)

	stdin.channel.send(request + ";\n")

	digest = genFileName(startDate, endDate) #hashlib.md5(request.encode("utf8")).hexdigest()
	digest2 = 'tempFile' + str(yearStart)
	print(digest)
	cachename = cache_dir / digest2

	title = "time	icao24	lat	lon	velocity	heading	vertrate	callsign	onground	alert	spi	squawk	baroaltitude	geoaltitude	lastposupdate	lastcontact	hour"


	total = ""
	while len(total) == 0 or total[-10:] != ":21000] > ":
	    b = stdout.channel.recv(256)
	    total += b.decode()

	for i in range(5000):
		if(total[i]==';'):
			break
	total =title + total[i+1:-21]
	with cachename.open("w") as fh:
	    fh.write("\n")
	    fh.write(total)

	fd= pd.read_csv(cachename, sep='\t')
	table = pa.Table.from_pandas(fd)
	newName = digest + '.parquet'
	newName = cache_dir / newName
	pq.write_table(table, newName)
	startDate = endDate

client.close()







