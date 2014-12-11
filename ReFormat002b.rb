# prescan a text file from Clear Care Schedules (Future) report to get clients names.
# process every line in a text file with ruby (09/12/2014). This program is tested on Ruby 2.0 in Babun

reports='New Text Document.txt' #This is the name of the Clear Care report pure text file name
f = File.open('output.txt', 'w')
require 'time'  #require 'pry'
# method for parsing text into time stamps
def read_shift(single_line)
#	return "Wrong line" unless single_line =~/^(\d{2})\/(\d{2})\/(\d{4})/
         shift_date=single_line.split(',')[0].split[0]
              shift=single_line.split(',')[1]
           cg=shift.split(':')[0]
  shift_start=shift.split('-')[0].split(':')
  if shift =~ /(\d{2})\/(\d{2})\/(\d{4})/ 
    startTime=Time.strptime(shift_start[1]+":"+shift_start[2], ' %m/%d/%Y %I:%M %p')
    endTime=Time.strptime(shift.split('-')[1], ' %m/%d/%Y %I:%M %p')
  else
    startTime=Time.strptime(shift_date+shift_start[1]+":"+shift_start[2], ' %m/%d/%Y %I:%M %p')
    endTime=Time.strptime(shift_date+shift.split('-')[1], ' %m/%d/%Y %I:%M %p')
  end
  [shift_date, cg, startTime, endTime]
end
#no declare no global?
shifts=''
rangestart=Date.new #for getting range to limit output
client_names=[]
yesterday='07/31/2014' #initial date globally required
main_start=Time.strptime(yesterday+" 12:00 AM", ' %m/%d/%Y %I:%M %p').to_i/60
residual=[] #create for last shift array
aday=Array(main_start..main_start+1439) #create a whole day array  
#Start parsing lines containing shifts
File.readlines(reports).each do |line|
  client_names << shifts if line =~ /^Address:/  #^address can get us the client name in the last line.
  yesterday, today=shifts[0..9], line[0..9] #cannot add /^Address:/
  shifts=line.chomp  #Important! make the current line as the loaded line.  
  rangestart=Time.strptime(shifts[12..21]+" 12:00 AM", '%m/%d/%Y %I:%M %p')   if line =~ /^Date Range:/
  if client_names!=''  && shifts =~/^(\d{2})\/(\d{2})\/(\d{4})/ then #shift lines always begin with ^dates. 
    shift_date, cg, startTime, endTime=read_shift(shifts)[0],read_shift(shifts)[1],read_shift(shifts)[2],read_shift(shifts)[3] #parsing shift time
    f.puts "#{rangestart.strftime("%B")} schedule for #{client_names.join}\r\n\r\n" if client_names.length==1 and rangestart.to_date>startTime.to_date
	if (yesterday != today) and (residual.length>0) then #if it's a different day from the last line. ""
      f.puts "Warning: please recheck 24hr coverage above...........................\r\n" if ((aday.length > 1) and (rangestart.to_date<startTime.to_date))
	  #f.puts "00"
	  f.printf("\r\n%s\t%s-%s%-9s\r\n",startTime.strftime("%^a.%m/%d"),startTime.strftime("%l:%M%p"), endTime.strftime("%l:%M%p"),cg)
	  main_start=Time.strptime(today+" 12:00 AM", ' %m/%d/%Y %I:%M %p').to_i/60 #For re-creating a new whole day array
	  aday=Array(main_start..main_start+1439)  # - residual
      aday = aday - residual  #take away the last shift array from the whole day array
	  residual=Array(startTime.to_i/60..endTime.to_i/60) #replace the last shift array by the current shift
      aday = aday - residual  #take away current shift time from whole day array
	else
	f.printf("\t\t%s-%s%-9s\r\n",startTime.strftime("%l:%M%p"), endTime.strftime("%l:%M%p"), cg) if (aday.length > 1 and rangestart.to_date<=startTime.to_date)# '=' require
    aday = aday - residual  #take away the last shift array from the whole day array
	residual=Array(startTime.to_i/60..endTime.to_i/60) #replace the last shift array by the current shift
	aday = aday - residual  #take away current shift time from whole day array
	end  
  else    
  end
 end
f.close

#todo: printing html head

#if client_names.length==1
#  puts "Schedules for #{client_names.join}" 
#else
#  puts "[b]Warning: found more than one clients. Please regenerate the Schedules (Future) report and choose only [i]ONE[/i] client, since currently this program can only process a single client[/b] "
#end
