import pandas as pd
import pyarrow.parquet as pq
from pathlib import Path
import calendar
import datetime

# Time
yearStart = 2019
monthStart = 2
dayStart = 1
hourStart = 0
cache_dir = Path('/data/database/Openskynet/opensky/cache_zurich')

def genFileName(sDate, eDate):
	fname = sDate.strftime("%Y%m%d%H")+'To'+eDate.strftime("%Y%m%d%H")
	return fname

fd= pd.read_csv('/data/database/Openskynet/opensky/cache_zurich/aircraftDatabase.csv')

startDate =  datetime.datetime(yearStart, monthStart, dayStart, hourStart, 0)
for month in range(10,40):
	endDate =  startDate + datetime.timedelta(days=7)
	digest = genFileName(startDate, endDate) 
	newName = digest + '.parquet'
	filename = cache_dir / newName
	data = pq.read_table(filename)
	data2 = data.to_pandas()
	test = data2.loc[(data2['baroaltitude'] )<=1000]
	na = test.icao24.unique()

	startDate = endDate
	for name in na:
		tmp = fd.loc[(fd['icao24'] )==name]
		tt = tmp.typecode.unique()
		if(tt.size==0):
			print('**Missing:' + name)
		else:
			t=tt[0]
			if(type(t)==float):
				print('Withoudata:' + name)
			else:
				test.loc[test['icao24'] == name, 'AircraftType'] = t

	test.drop(['callsign', 'alert', 'spi', 'squawk'], axis=1,inplace=True)
	saveName = 'weekFromFeb%02d' %month + '.csv' 
	test.to_csv(saveName)
	
	del data
	del data2
	del test
	del na




