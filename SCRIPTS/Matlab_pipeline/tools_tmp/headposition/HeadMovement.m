clear all;

DataDir = 'Y:\protocols\MEG\LanguageSynax_Masaki\Analysis\Maxfilter\SSS_SubtAmp\';

SaveFileName = 'HeadMovements.txt';
fid_all = fopen([DataDir SaveFileName], 'w');
fprintf(fid_all, '%c', 'Sub');fprintf(fid_all, '%c\t', '');
fprintf(fid_all, '%c', 'PosiDiffAcrossRuns');fprintf(fid_all, '%c\t', '');
fprintf(fid_all, '%c', 'AngXYDiffAcrossRuns');fprintf(fid_all, '%c\t', '');
fprintf(fid_all, '%c', 'AngYZDiffAcrossRuns');fprintf(fid_all, '%c\t', '');
fprintf(fid_all, '%c', 'AngZXDiffAcrossRuns');fprintf(fid_all, '%c\t', '');
fprintf(fid_all, '%c', 'PosiDiffWithinRuns');fprintf(fid_all, '%c\t', '');
fprintf(fid_all, '%c', 'AngDiffWithinRuns');fprintf(fid_all, '%c\n', '');

SubDir = dir(DataDir);

cut_end_period = 15;

s = 0;
for allfile = 1:length(SubDir)
    
    if SubDir(allfile).isdir == 1 && strncmp(SubDir(allfile).name, '.', 1) == 0
        DataFile = dir(strcat(DataDir, SubDir(allfile).name, '\*run*_hp.txt'));
        s= s+1;
        Position_AllR = [];
        Angle_AllR = [];
        MaxMovePosi_EachR = 0;
        MaxMoveAngle_EachR = 0;
        
        for f = 1:length(DataFile);
            fid = fopen(strcat(DataDir, SubDir(allfile).name, '\', DataFile(f).name), 'r');
            for H_Elements = 1:10
                Header{H_Elements} = fscanf(fid, '%s/t');
            end
            
            Data = fscanf(fid, '%f', [10,inf]);
            fclose(fid);
            time = Data(1,:);
            clear R
            Data(1,:) = sqrt(1 - (Data(2,:).^2 + Data(3,:).^2 + Data(4,:).^2));
            R(1,1,:) = Data(1,:).^2 + Data(2,:).^2 - Data(3,:).^2 - Data(4,:).^2;
            R(1,2,:) = 2*(Data(2,:).*Data(3,:).^2 - Data(1,:).*Data(4,:));
            R(1,3,:) = 2*(Data(2,:).*Data(4,:).^2 + Data(1,:).*Data(3,:));
            R(2,1,:) = 2*(Data(2,:).*Data(3,:).^2 + Data(1,:).*Data(4,:));
            R(2,2,:) = Data(1,:).^2 + Data(3,:).^2 - Data(2,:).^2 - Data(4,:).^2;
            R(2,3,:) = 2*(Data(3,:).*Data(4,:).^2 - Data(1,:).*Data(2,:));
            R(3,1,:) = 2*(Data(2,:).*Data(4,:).^2 - Data(1,:).*Data(3,:));
            R(3,2,:) = 2*(Data(3,:).*Data(4,:).^2 + Data(1,:).*Data(2,:));
            R(3,3,:) = Data(1,:).^2 + Data(4,:).^2 - Data(2,:).^2 - Data(3,:).^2;
            
            Axy = abs(pi - abs(pi - abs(angle(R(1,1,:) + R(1,2,:) + R(1,3,:) + 1i*(R(2,1,:) + R(2,2,:) + R(2,3,:))) - angle(1+1i))));
            Ayz = abs(pi - abs(pi - abs(angle(R(2,1,:) + R(2,2,:) + R(2,3,:) + 1i*(R(3,1,:) + R(3,2,:) + R(3,3,:))) - angle(1+1i))));
            Azx = abs(pi - abs(pi - abs(angle(R(3,1,:) + R(3,2,:) + R(3,3,:) + 1i*(R(1,1,:) + R(1,2,:) + R(1,3,:))) - angle(1+1i))));
            
            AxyMax = 0;
            AyzMax = 0;
            AzxMax = 0;
            TransMax = 0;
            end_slice = max(find(time < time(end) - cut_end_period));
            for m = 1:length(Data(1,1:end_slice))-1
                for n = m+1:length(Data(1,1:end_slice))
                    AxyD = abs(pi - abs(pi - abs(Axy(m)-Axy(n))));
                    AyzD = abs(pi - abs(pi - abs(Ayz(m)-Ayz(n))));
                    AzxD = abs(pi - abs(pi - abs(Azx(m)-Azx(n))));
                    TransD = sqrt((Data(5,m)-Data(5,n)).^2 + ...
                        (Data(6,m)-Data(6,n)).^2 + (Data(7,m)-Data(7,n)).^2);
                    if TransD > TransMax
                        TransMax = TransD;
                    end
                    if AxyD > AxyMax
                        AxyMax = AxyD;
                    end
                    if AyzD > AyzMax
                        AyzMax = AyzD;
                    end
                    if AzxD > AzxMax
                        AzxMax = AzxD;
                    end
                end
            end
            
            
            for j = 5:7
                Trans(j-4) = max(Data(j,1:end_slice)) - min(Data(j,1:end_slice));
            end
            
            %units mm, deg
            
            DataFile(f).name
            num2str(round([Trans TransMax]*1000), '%d\t')
            num2str(round([AxyMax AyzMax AzxMax]/pi*180), '%d\t')
            
            LookTime = 10;
            Position_AllR(:,f) = Data(5:7,LookTime);
            Angle_AllR(:,f) = [Axy(LookTime) Ayz(LookTime) Azx(LookTime)];
            
            if TransMax > MaxMovePosi_EachR
                MaxMovePosi_EachR = TransMax;
            end
            if max([AxyMax AyzMax AzxMax]) > MaxMoveAngle_EachR
                MaxMoveAngle_EachR = max([AxyMax AyzMax AzxMax]);
            end
        end
    
    
    
    AngleMax_AllR = zeros(3,1);
    TransMax_AllR = 0;
    for m = 1:length(Position_AllR(1,:))-1
        for n = m+1:length(Position_AllR(1,:))
            AngleD = abs(pi - abs(pi - abs(Angle_AllR(:,m) - Angle_AllR(:,n))));
            TransD = sqrt((Position_AllR(1,m)-Position_AllR(1,n)).^2 + ...
                (Position_AllR(2,m)-Position_AllR(2,n)).^2 + (Position_AllR(3,m)-Position_AllR(3,n)).^2);
            if TransD > TransMax_AllR
                TransMax_AllR = TransD;
            end
            if AxyD > AngleMax_AllR(1)
                AngleMax_AllR(1) = AngleD(1);
            end
            if AyzD > AngleMax_AllR(2)
                AngleMax_AllR(2) = AngleD(1);
            end
            if AzxD > AngleMax_AllR(3)
                AngleMax_AllR(3) = AngleD(1);
            end
        end
    end
    
    
    fprintf(fid_all, '%c', SubDir(allfile).name);fprintf(fid_all, '%c\t', '');
    fprintf(fid_all, '%i\t', [TransMax_AllR*1000 AngleMax_AllR'/pi*180 MaxMovePosi_EachR*1000 MaxMoveAngle_EachR/pi*180]);
    fprintf(fid_all, '%c\n', '');
    
        end

end

fclose(fid_all)

