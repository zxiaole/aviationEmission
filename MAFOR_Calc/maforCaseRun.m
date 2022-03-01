function maforCaseRun(hourId,refEmissions, refBackgrounds, duration, hour, day, month, u10, dilcoef, concInit, concBackground, distanceInit, rain, temperature, humidity)
%%
% Dec. 17, 2019, Xiaole Zhang
% automatically run MAFOR code
% temperature unit: C
%%
Kfactor = 273.15;

refTemp = [0 10 20 30];
vtemp = temperature-refTemp;
[vtemp, idtemp] = min(abs(vtemp));
refTemp = refTemp(idtemp);
refEm = refEmissions(idtemp, 2);
refBackground = refBackgrounds(idtemp, 2);

source = [num2str(refTemp) 'degree'];

%% copy files
destination = [num2str(hourId) '_' source '_' num2str(dilcoef) '_u10_' num2str(u10)];

flag = exist(destination, 'dir');
if(flag)
    dataTmp = importdata([destination '/size_dis.res']);
    flagWrong = isempty(dataTmp);
end

if(flag&&~flagWrong)
    disp('Exist calculation')
else
    if(~flag)
        mkdir(destination);
    end
    
    %% revise ingeod.dat: speed, dilution, day, month
    fid = fopen([source '/ingeod.dat'],'r');
    strtmp = fgetl(fid);
    vars = regexp(strtmp, '\s+|\t', 'split' );
    fclose(fid);
    
    fod = fopen(['./' destination '/ingeod.dat'],'w');
    for lineN = 1:duration
        vars{1} = num2str(duration);
        vars{2} = num2str(day);
        vars{3} = num2str(month);
        vars{4} = num2str(hour);
        vars{7} = num2str(temperature+Kfactor);
        vars{9} = num2str(min(humidity/100, 0.99));
        vars{12} = num2str(u10);
        vars{13} = num2str(rain);
        vars{25} = num2str(dilcoef);
        
        strtmp = [];
        for varsN = 1:25
            strtmp = [strtmp vars{varsN} '\t'];
        end
        fprintf(fod, [strtmp '\n']);
    end
    fclose(fod);
    
    
    %% revise the inaero.dat
    fod = fopen(['./' destination '/inaero.dat'], 'w');
    fid = fopen(['./' source '/inaero.dat']);
    emissionFactor = concInit/refEm;
    for lineN = 1:5
        strtmp = fgetl(fid);
        if(lineN>1)
            vars = regexp(strtmp, '\s+|\t', 'split' );
            strtmp = [];
            for varsN = 1:13
                if(varsN>=5)
                    vars{varsN} = num2str(str2double(vars{varsN})*emissionFactor);
                end
                strtmp = [strtmp vars{varsN} '\t'];
            end
            
        end
        fprintf(fod, [strtmp '\n']);
    end
    fclose(fid);
    fclose(fod);
    
    %% copy the dispers.dat
    fod = fopen(['./' destination '/dispers.dat'], 'w');
    fid = fopen(['./' source '/dispers.dat']);
    for lineN = 1:5
        strtmp = fgetl(fid);
        if(lineN==1)
            vars = regexp(strtmp, '\s+|\t', 'split' );
            vars{2} = num2str(distanceInit);
            vars{4} = num2str(temperature+Kfactor);
            strtmp = [];
            for varsN = 1:4
                strtmp = [strtmp vars{varsN} '\t'];
            end
            
        end
        fprintf(fod, [strtmp '\n']);
    end
    fclose(fid);
    fclose(fod);
    
    %% copy the inbgair.dat
    fod = fopen(['./' destination '/inbgair.dat'], 'w');
    fid = fopen(['./' source '/inbgair.dat']);
    factor = concBackground/refBackground;
    for lineN = 1:5
        strtmp = fgetl(fid);
        if(lineN<5)
            vars = regexp(strtmp, '\s+|\t', 'split' );
            strtmp = [];
            for varsN = 1:11
                if(varsN>2)
                    vars{varsN} = num2str(str2double(vars{varsN})*factor);
                end
                strtmp = [strtmp vars{varsN} '\t'];
            end
            
        end
        fprintf(fod, [strtmp '\n']);
    end
    fclose(fid);
    fclose(fod);
    
    %% copy the sensitive.dat
    copyfile([source '/sensitiv.dat'], destination);
    
    %% copy the inchem.dat
    copyfile([source '/inchem.dat'], destination);
    %% copy the organic.dat
    copyfile([source '/organic.dat'], destination);
    
    %% copy the MAFOR_v19_ubuntu64.exe
    copyfile([source '/MAFOR_v19_ubuntu64.exe'], destination);
    
    %% run the program
    cd(destination)
    tic
    unix('./MAFOR_v19_ubuntu64.exe >& log')
    tc = toc;
    disp(tc)
    
    delete 'MAFOR_v19_ubuntu64.exe'
    cd('..')
end
%%


end

