function contaminantDistribution
% Script for determining distribution of contaminants according to 
% case-scenario. Select data from the pop-up menu, then click on plot. 

clear all
home

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% START VARIABLES  & INITIALIZATION

%-----------------------------------------------------------------------------
%Using Raoult's Law to estimate consentrations with increasasing watervolume
%Raoult's law:
%Si = Xi · S0
%   Si = solubility of compound i in equilibrium with mixture (mg/l)
%   Xi = Mol fraction of compound i in mixture (mol/mol)
%   S0 = pure compound solubility (mg/l) 
%-----------------------------------------------------------------------------

%Intitial conditions
t = 0;                  %time 0
Wa_I = 10;              %water-increase 44781 litres per year
So_Tol = 515;           %pure compound solubility toluene
So_Nap = 31;            %pure compound solubility naphthalene

D_BJF = 800.0;          %Density of bulk jet-fuel in g/l
Tol_Content = 10.64;    %mg/l of toluene
Nap_Content = 4.00;     %mg/l of naphthalene
Mw_BJF = 142.0;         %molecular weight of bulk jet-fuel in g/mol
Mw_Tol = 92.1;          %molecular weight of toluene in g/mol
Mw_Nap = 128.2;         %molecular weight of naphthalene in g/mol

%Determine concentration (M) of bulk jet-fuel in mol/l
M_BJF = D_BJF/Mw_BJF;

Si_Tol = 0;             %value before calculation
Si_Nap = 0;             %value before calculation


%-----------------------------------------------------------------------------
%Henry's law calculations, using Si_Tol and Si_Nap values from Raoult's law
%-----------------------------------------------------------------------------
Kh_Tol = 0.27;          %Henry's law constant from table 2.3 at 25deg
Kh_Nap = 0.02;          %Henry's law constant from table 2.3 at 25deg


%-----------------------------------------------------------------------------
%Mixing and ditribution
%-----------------------------------------------------------------------------
Mt = 0;                 %initial mixingtime
Td = 0;                 %initial traveldistance

Dt = 84507;             %Distribution-time in seconds relative to 10:1 mix,
                        %moving 1 m^2 containing 12 litres of jetfuel.
Vp = 3.86*10^-6;        %Porewater-velocity in m/s, negative sign disregarded
TdI = Vp*Dt;            %Travel-distance increasse. Relates to Dt.




%-----------------------------------------------------------------------------
% Half-life, using 1st order decay-rate and C0·e^-k1t=Ct where 
%   C0 = the original concentration
%   k1 = the decay-constant
%   t = time in days
%   Ct = Concentration after time t
%Values after Wiedemeier et al. 1999
k1_TolW = 0.02475;
k1_NapW = 0.002686;

%Values after Zheng et al. 2001
k1_TolZ = 0.009;            %Toluene Zheng
k1_TolZMix = 0.065;         %Mean toluene mixed with other: 0.065
k1_NapZ = 0;

k1_Tol = k1_TolZ;           %Change values for different scenarios (eg. Zheng)
k1_Nap = k1_NapW;

Ct_Tol = 0;                 %value before calculation
Ct_Nap = 0;                 %value before calculation
Ct_Tol_Diff = 0;            %Difference in concentration before 
                            %and after degradation-calculation
Ct_Nap_Diff = 0; 

DTimeID = Dt/(60*60*24);    %decaytime-increase in days. Relates to 
                            %mixingtime in days
%-------------------------------------------------------------------------
% SOIL
% Organic carbon content, used for calculating Kd and soil concentration
foc = 0.0008;              %foc: min=0.0008, max=0.0041, avg=0.00245
Csoil_Tol_Diff = 0;         %value before calculation
Csoil_Nap_Diff = 0; 

%Toluene
logKow_Tol = 2.69;                            %using constant logKow-value
Koc_Tol = 10^((0.989*logKow_Tol)-0.346);
Kd_Tol = foc*Koc_Tol;                         %calculate Kd

%Naphthalene
logKow_Nap = 3.37;                            %using constant logKow-value
Koc_Nap = 10^((0.989*logKow_Nap)-0.346);
Kd_Nap = foc*Koc_Nap;                         %calculate Kd

%-------------------------------------------------------------------------
% RETARDATION
% Using R = 1 +[(pb)/n]* Kd where
%   pb = bulk density of soil (kg/l = tonnes/m3)
%   n = porosity (m3/m3) and
%   Kd = distribution coefficient soil-water (l/kg)
%
% And vc = vp/R where
%   vc = transport velocity of contaminant (m/s)
%   vp = groundwater velocity (m/s)
%   R = retardatjon factor (-/-)

pb = 1.68;
n = 0.367;

%Toluene
RTol = 1+(pb/n)*Kd_Tol;
vcTol = Vp/RTol;        %Velocity in m/s
TdTolR = 0;             %Initial traveldistance with retardation
TdITolR = vcTol*Dt;     %Travel-distance increasse with retardation. 
                        %Relates to Dt.


%Naphthalene
RNap = 1+(pb/n)*Kd_Nap;
vcNap = Vp/RNap;        %Velocity in m/s
TdNapR = 0;             %Initial traveldistance with retardation
TdINapR = vcNap*Dt;     %Travel-distance increasse with retardation. 
                        %Relates to Dt.

                        
                        
% Preallocating some space in arrays
Td_i = zeros(1, 50);
TdTolR_i = zeros(1, 50);
TdNapR_i = zeros(1, 50);
Si_Tol_i = zeros(1, 50);
Si_Nap_i = zeros(1, 50);
Cg_Tol_i = zeros(1, 50);
Cg_Nap_i = zeros(1, 50);
Csoil_Tol_i = zeros(1, 50);
Csoil_Nap_i = zeros(1, 50);
Mt_i = zeros(1, 50); 

%Setting initial concentrations
Cg_Tol = 0; 
Cg_Nap = 0;
Csoil_Tol = 0;                        
Csoil_Nap = 0; 

%Adjusting values for toluene and naphthalene upon mixing
concentration_ok=0.0001;    %Drinkingwater limit, 
                            %0,1 micro_g/L = 0.0001 mg/l
condition = 1;              %just a startingpoint,
                            %condition updated at end of while

currentContaminant = 'toluene'; %Start default contaminant
current_data = 1; %Start default value, NO retardation

% END VARIABLES & INITIALIZATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GUI AND POSITIONING

% Create and then hide the UI as it is being constructed.
f = figure('Position',[0,0,800,600]);
f.NumberTitle = 'off';
f.Resize = 'off';
f.Name = 'Contaminants';
movegui(f,'center')

%Positioning axes
ha = axes('Units','pixels','Position',[100,100,600,400]);

% Adding and positioning buttons and text
yPos = 560;
hContaminantText  = uicontrol('Style','text','String','Contaminant:',...
           'Position',[10,yPos-5,80,25]);
       
hToluene    = uicontrol('Style','pushbutton',...
             'String','Toluene','Position',[100,yPos,100,25],...
             'Callback',{@tolueneButton_Callback});
      
hNaphthalene= uicontrol('Style','pushbutton',...
             'String','Naphthalene','Position',[200,yPos,100,25],...
             'Callback',{@naphthaleneButton_Callback});        

% Adding the pop-up menu and its static text label
hPupuptext  = uicontrol('Style','text','String','Select Data:',...
           'Position',[320,yPos-5,70,25]);
           %Static text: 'text' -> 'Select Data' -> NO CALLBACK
       
hpopup = uicontrol('Style','popupmenu',...
           'String',{'With constraints','Without constraints'},...
           'Position',[390,yPos,150,25],...
           'Callback',{@popup_menu_Callback});


% END GUI AND POSITIONING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %Setting up the Pop-Up
    function popup_menu_Callback(source,eventdata) 
      %Set selected data.
      val = source.Value;
      %resetVariables();
      
      switch val;
            %case 'With retardation'  
            case 1 
                disp('With constraints')
                
                current_data = 1; %'With retardation'
                 
%                 if contains('toluene', currentContaminant)
%                     calculateToluene();
%                 else 
%                     calculateNaphthalene();
%                 end

            case 2 
                disp('Without constraints')
                
                current_data = 2; %'Without retardation'
                
%                 if contains('toluene', currentContaminant)
%                     calculateToluene();
%                 else 
%                     calculateNaphthalene();
%                 end
      end
    end


% Push button callbacks.
function tolueneButton_Callback(source,eventdata)
     resetVariables();
     calculateToluene();
     plotContaminant('toluene');
end

function naphthaleneButton_Callback(source,eventdata) 
     resetVariables();
     calculateNaphthalene();
     plotContaminant('naphthalene');
end



function plotContaminant(str) 
    currentContaminant = str;
    
    % clear axes before plotting
    cla(ha);
    
    switch str
        case 'toluene'
            disp ('TOOL')
            if current_data == 1
                disp ('WITH retard')
                % -----------------------------------------------------------------------------                                              
                % RETARDATION, SORPTION AND BIODEGREDATION Plotting TOLUENE
                hold on
                caption = sprintf('Graph of evolving toluene water- and gas-concentration vs travel-distance.\nWith retardation, sorption and biodegredation.');
                title(caption)
                
                plot(TdTolR_i, Si_Tol_i,'r','LineWidth',1.5);
                plot(TdTolR_i, Cg_Tol_i ,'b','LineWidth',1.5);
                plot(TdTolR_i, Csoil_Tol_i,'g','LineWidth',1.5);
                ylabel('Concentrations: water(mg/l), gas-phase(g/m^3), soil(mg/kg)')
                xlabel('Travel-distance in meters')
                       
                %Toluene text, water-concentration
                strConsStart_T=['\color{red}Start: ',num2str(Si_Tol_i(1)),' mg/l'];
                text(TdTolR_i(1),Si_Tol_i(1)+0.5,strConsStart_T,'HorizontalAlignment','left');
                strConsEnd_T=['\color{red}End: ',num2str(Si_Tol),' mg/l'];
                text(TdTolR_i(t),Si_Tol_i(t)+1.5,strConsEnd_T,'HorizontalAlignment','right');
                
                % Toluene text, gas-concentration
                strConsStart_N=['\color{blue}Start: ',num2str(Cg_Tol_i(1)),' g/m^3'];
                text(TdTolR_i(1),Cg_Tol_i(1)+0.5,strConsStart_N,'HorizontalAlignment','left');
                strConsEnd_N=['\color{blue}End: ', num2str(Cg_Tol),' g/m^3'];
                text(TdTolR_i(t),1,strConsEnd_N,'HorizontalAlignment','right');
                
                % Toluene text, sorption
                strConsStart_N=['\color{green}Start: ',num2str(Csoil_Tol_i(1)),' mg/kg'];
                text(TdTolR_i(1),Csoil_Tol_i(1)+0.5,strConsStart_N,'HorizontalAlignment','left');
                strConsEnd_N=['\color{green}End: ', num2str(Csoil_Tol),' mg/kg'];
                text(TdTolR_i(t),0.5,strConsEnd_N,'HorizontalAlignment','right');
                
                %InfoBox
                maxX = get(gca,'xlim');
                maxY = get(gca,'ylim');
                
                Time_T=['\color{gray}Time: ',num2str(Mt_i(t),'%.2f'),' days.'];
                text(maxX(2)-0.15,maxY(2)-3,Time_T,'HorizontalAlignment','right');
                
                Distance_T=['\color{gray}Distance: ',num2str(TdTolR_i(t),'%.2f'),' meters.'];
                text(maxX(2)-0.15,maxY(2)-3.5,Distance_T,'HorizontalAlignment','right');
                hold off

                leg = legend('Water','Gas','Soil');
                title(leg,'Concentrations')
                leg.Visible = 'on';
                
                ax = f.CurrentAxes;
                ax.XTickLabelRotation = -45;
            
            else
                disp ('no retard')
                % -----------------------------------------------------------------------------
                % NO RETARDATION Plotting TOLUENE
                hold on
                caption = sprintf('Graph of evolving toluene water- and gas-concentration vs travel-distance.\nNo retardation, sorption or biodegredation.');
                title(caption)
                
                plot (Td_i, Si_Tol_i,'r','LineWidth',1.5)
                plot (Td_i, Cg_Tol_i ,'b','LineWidth',1.5)
                ylabel('Concentration in water (mg/l) and gas-phase (g/m^3)')
                xlabel('Travel-distance in meters')
                
                ax = f.CurrentAxes;
                ax.XTickLabelRotation = -45;
                
                %Toluene text, water-concentration
                strConsStart_T=['\color{red}Start: ',num2str(Si_Tol_i(1)),' mg/l'];
                text(Td_i(1),Si_Tol_i(1)+0.5,strConsStart_T,'HorizontalAlignment','left');
                strConsEnd_T=['\color{red}End: ',num2str(Si_Tol),' mg/l'];
                text(Td_i(t),Si_Tol_i(t)+1,strConsEnd_T,'HorizontalAlignment','right');
                
                % Toluene text, gas-concentration
                strConsStart_N=['\color{blue}Start: ',num2str(Cg_Tol_i(1)),' g/m^3'];
                text(Td_i(1),Cg_Tol_i(1)+0.5,strConsStart_N,'HorizontalAlignment','left');
                strConsEnd_N=['\color{blue}End: ', num2str(Cg_Tol),' g/m^3'];
                text(Td_i(t),0.5,strConsEnd_N,'HorizontalAlignment','right');
                
                %InfoBox
                maxX = get(gca,'xlim');
                maxY = get(gca,'ylim');
                
                Time_T=['\color{gray}Time: ',num2str(Mt_i(t),'%.2f'),' days.'];
                text(maxX(2)-5.4,maxY(2)-2.5,Time_T,'HorizontalAlignment','right');
                
                Distance_T=['\color{gray}Distance: ',num2str(Td_i(t),'%.2f'),' meters.'];
                text(maxX(2)-5.4,maxY(2)-3,Distance_T,'HorizontalAlignment','right');
                       
                hold off
                
                leg = legend('Water','Gas');
                title(leg,'Concentrations')
                leg.Visible = 'on';
                
                ax = f.CurrentAxes;
                ax.XTickLabelRotation = -45;            
            end
            
        case 'naphthalene'
            disp ('NAAAA')
            if current_data == 1 %With retardation
                disp ('WITH retard')
                % -----------------------------------------------------------------------------
                %RETARDATION, SORPTION AND BIODEGREDATION Plotting NAPHTHALENE
                hold on
                caption = sprintf('Graph of evolving naphthalene water- and gas-concentration vs travel-distance.\nWith retardation, sorption and biodegredation.');
                title(caption)
                
                plot(TdNapR_i, Si_Nap_i,'r','LineWidth',1.5)
                plot(TdNapR_i, Cg_Nap_i ,'b','LineWidth',1.5)
                plot(TdNapR_i, Csoil_Nap_i,'g','LineWidth',1.5)
                ylabel('Concentrations: water(mg/l), gas-phase(g/m^3), soil(mg/kg)')
                xlabel('Travel-distance in meters')
                
                %Naphthalene text, water-concentration
                strConsStart_T=['\color{red}Start: ',num2str(Si_Nap_i(1)),' mg/l'];
                text(TdNapR_i(1),Si_Nap_i(1)+0.005,strConsStart_T,'HorizontalAlignment','left');
                strConsEnd_T=['\color{red}End: ',num2str(Si_Nap),' mg/l'];
                text(TdNapR_i(t),Si_Nap_i(t)+0.02,strConsEnd_T,'HorizontalAlignment','right');
                
                strConsStart_N=['\color{blue}Start: ',num2str(Cg_Nap_i(1)),' g/m^3'];
                text(TdNapR_i(1),0.01,strConsStart_N,'HorizontalAlignment','left');
                strConsEnd_N=['\color{blue}End: ', num2str(Cg_Nap),' g/m^3'];
                text(TdNapR_i(t),0.01,strConsEnd_N,'HorizontalAlignment','right');
                
                % Toluene text, sorption
                strConsStart_N=['\color{green}Start: ',num2str(Csoil_Nap_i(1)),' mg/kg'];
                text(TdNapR_i(1),0.137,strConsStart_N,'HorizontalAlignment','left');
                strConsEnd_N=['\color{green}End: ', num2str(Csoil_Nap),' mg/kg'];
                text(TdNapR_i(t),0.03,strConsEnd_N,'HorizontalAlignment','right');
                
                %InfoBox
                maxX = get(gca,'xlim');
                maxY = get(gca,'ylim');
                
                Time_T=['\color{gray}Time: ',num2str(Mt_i(t),'%.2f'),' days.'];
                text(maxX(2)-0.5,maxY(2)-0.045,Time_T,'HorizontalAlignment','right');
                
                Distance_T=['\color{gray}Distance: ',num2str(TdNapR_i(t),'%.2f'),' meters.'];
                text(maxX(2)-0.5,maxY(2)-0.052,Distance_T,'HorizontalAlignment','right');
                
                hold off             
                
                leg = legend('Water','Gas','Soil');
                title(leg,'Concentrations')
                leg.Visible = 'on';
                
                ax = f.CurrentAxes;
                ax.XTickLabelRotation = -45;       
                
            else
                disp ('no retard')
                %-----------------------------------------------------------------------------
                %NO RETARDATION Plotting NAPHTHALENE
                hold on
                caption = sprintf('Graph of evolving naphthalene water- and gas-concentration vs travel-distance.\nNo retardation, sorption or biodegredation.');
                title(caption)
                
                %plot (TdTolR_i, Si_Tol_i,'b','LineWidth',1.5)
                plot (Td_i, Si_Nap_i,'r','LineWidth',1.5)
                plot (Td_i, Cg_Nap_i ,'b','LineWidth',1.5)
                ylabel('Concentration in water (mg/l) and gas-phase (g/m^3)')
                xlabel('Travel-distance in meters')
                
                %Naphthalene text, water-concentration
                strConsStart_T=['\color{red}Start: ',num2str(Si_Nap_i(1)),' mg/l'];
                text(Td_i(1),Si_Nap_i(1)+0.005,strConsStart_T,'HorizontalAlignment','left');
                strConsEnd_T=['\color{red}End: ',num2str(Si_Nap),' mg/l'];
                text(Td_i(t),Si_Nap_i(t)+0.02,strConsEnd_T,'HorizontalAlignment','right');
                
                strConsStart_N=['\color{blue}Start: ',num2str(Cg_Nap_i(1)),' g/m^3'];
                text(Td_i(1),Cg_Nap_i(1)+0.006,strConsStart_N,'HorizontalAlignment','left');
                strConsEnd_N=['\color{blue}End: ', num2str(Cg_Nap),' g/m^3'];
                text(Td_i(t),Cg_Nap_i(t)+0.01,strConsEnd_N,'HorizontalAlignment','right');
                
                %InfoBox
                maxX = get(gca,'xlim');
                maxY = get(gca,'ylim');
                
                Time_T=['\color{gray}Time: ',num2str(Mt_i(t),'%.2f'),' days.'];
                text(maxX(2)-80,maxY(2)-0.038,Time_T,'HorizontalAlignment','right');
                
                Distance_T=['\color{gray}Distance: ',num2str(Td_i(t),'%.2f'),' meters.'];
                text(maxX(2)-80,maxY(2)-0.045,Distance_T,'HorizontalAlignment','right');
                
                hold off
                
                leg = legend('Water','Gas');
                title(leg,'Concentrations')
                leg.Visible = 'on';
                
                ax = f.CurrentAxes;
                ax.XTickLabelRotation = -45;
                
            end
    end

    
end


function calculateNaphthalene()
    
    while (condition>concentration_ok) 
    t=t+1;                                              %time-step

    %-----------------------------------
    %Time and distance values
    WaI_i(t) = t*10;               %watervolume values in array
    
    Mt = Mt + Dt;                  %Mixingtime increase pr. iteration
    Mtd = (Mt/(60*60*24));         %Mixingtime in days 
    Mt_i(t) = Mtd;                 %Mixingtime in days into array
    
    Td = Td + TdI;                 %Traveldistance increase pr. iteration
    Td_i(t) = Td;
    
    %Naphthalene
    if current_data==2
        Ct_Nap_Diff = 0;  %No retardation, sorption or biodegredation
    end

    Nap_Content = Nap_Content - ((Si_Nap/1000)*Wa_I)-Ct_Nap_Diff;
    Nap_Content_i(t) = Nap_Content;
    M_Nap = Nap_Content/Mw_Nap;
    MF_Nap = M_Nap/M_BJF;
    Si_Nap = So_Nap*MF_Nap;
    Si_Nap_i(t) = Si_Nap;                               
    

    Cg_Nap = (Kh_Nap*Si_Nap);           %Concentration gas-phase by Henry
    Cg_Nap_i(t) = Cg_Nap;
   
    %-----------------------------------
    %Degredation-implementation
    Ct_Nap = Si_Nap*(exp(1)^(-k1_Nap*Mtd));     %calculate concentration
    Ct_Nap_i(t) = Ct_Nap;                       %values into array   
    Ct_Nap_Diff = Si_Nap - Ct_Nap;
    %-----------------------------------
    
    %-----------------------------------
    %SOIL
    %Calculating Kd and soil concentration
    
    Csoil_Nap = Kd_Nap*Si_Nap;                  %calculate Csoil  
    Kd_Nap_i(t) = Kd_Nap;                       %values into array   
    Csoil_Nap_i(t) = Csoil_Nap;                 %values into array
    
    %-----------------------------------
    
    
    %-----------------------------------
    %Traveldistance with retardation
    TdNapR = TdNapR + TdINapR;            %Naphthalene distance increasse
    TdNapR_i(t) = TdNapR;
    
   
    %-----------------------------------
    %Tolerance vs compund [Si_Tol or Si_Nap]
    condition = Si_Nap;                    %change between compounds 
end
    
    
end

function calculateToluene()

    while (condition>concentration_ok)
        t=t+1;                                             %time-step
        
        %-----------------------------------
        %Time and distance values
        WaI_i(t) = t*10;               %watervolume values in array
        
        Mt = Mt + Dt;                  %Mixingtime increase pr. iteration
        Mtd = (Mt/(60*60*24));         %Mixingtime in days
        Mt_i(t) = Mtd;                 %Mixingtime in days into array
        
        Td = Td + TdI;                 %Traveldistance increase pr. iteration
        Td_i(t) = Td;
        
        
        %Toluene
        if current_data==2 
            Ct_Tol_Diff = 0; %No retardation, sorption or biodegredation
        end
        
        Tol_Content = Tol_Content - ((Si_Tol/1000)*Wa_I)-Ct_Tol_Diff;
        
        Tol_Content_i(t) = Tol_Content;     %content values in array
        M_Tol = Tol_Content/Mw_Tol;         %concentration of toluene in mol/l
        MF_Tol = M_Tol/M_BJF;               %molfraction of toluene
        %compared to bulk jet-fuel
        Si_Tol = So_Tol*MF_Tol;             %solubility of mixture
        %according to Raoult's law
        Si_Tol_i(t) = Si_Tol;               %solubility values in array
        
        
        Cg_Tol = (Kh_Tol*Si_Tol);           %Concentration gas-phase by Henry
        Cg_Tol_i(t) = Cg_Tol;
        
        
        %-----------------------------------
        %Degredation-implementation
        Ct_Tol = Si_Tol*(exp(1)^(-k1_Tol*Mtd));     %calculate concentration
        Ct_Tol_i(t) = Ct_Tol;                       %values into array
        Ct_Tol_Diff = Si_Tol - Ct_Tol;
        %-----------------------------------
        
        %-----------------------------------
        %SOIL
        %Calculating Kd and soil concentration
        Csoil_Tol = Kd_Tol*Si_Tol;                  %calculate Csoil
        Kd_Tol_i(t) = Kd_Tol;                       %values into array
        Csoil_Tol_i(t) = Csoil_Tol;                 %values into array
        
        %-----------------------------------
        %Traveldistance with retardation
        TdTolR = TdTolR + TdITolR;            %Toluene distance increasse
        TdTolR_i(t) = TdTolR;
        
        %-----------------------------------
        %Tolerance vs compund [Si_Tol or Si_Nap]
        condition = Si_Tol;                    %change between compounds
    end
      
end

    function resetVariables()
       
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  Reset of variables to ensure correct calculations on change

        t = 0;                 
        Wa_I = 10;             
        So_Tol = 515;           
        So_Nap = 31;            
        
        D_BJF = 800.0;          
        Tol_Content = 10.64;    
        Nap_Content = 4.00;     
        Mw_BJF = 142.0;         
        Mw_Tol = 92.1;          
        Mw_Nap = 128.2;         
        
        M_BJF = D_BJF/Mw_BJF;
        
        Si_Tol = 0;            
        Si_Nap = 0;          
        
        Kh_Tol = 0.27;        
        Kh_Nap = 0.02;       
        
        Mt = 0;              
        Td = 0;               
        
        Dt = 84507;           
        Vp = 3.86*10^-6;        
        TdI = Vp*Dt;         
        
 %-----  Do not reset if implementing manual value-change     
        k1_TolW = 0.02475;
        k1_NapW = 0.002686;
        
        %Values after Zheng et al. 2001
        k1_TolZ = 0.009;            %Toluene Zheng
        k1_TolZMix = 0.065;         %Mean toluene mixed with other1: 0.065
        k1_NapZ = 0;
        
        k1_Tol = k1_TolZ;           %Exchange values for different scenarios
        k1_Nap = k1_NapW;
 %-----      
        Ct_Tol = 0;                
        Ct_Nap = 0;                 
        Ct_Tol_Diff = 0;            
        Ct_Nap_Diff = 0;
        
        DTimeID = Dt/(60*60*24);  
%#¤&    Do not reset foc if implementing manual value-change
        %foc = 0.0008;              %foc: min=0.0008, max=0.0041, avg=0.00245
        Csoil_Tol_Diff = 0;        
        Csoil_Nap_Diff = 0;
        
        logKow_Tol = 2.69;                            
        Koc_Tol = 10^((0.989*logKow_Tol)-0.346);
        Kd_Tol = foc*Koc_Tol;                        
        
        logKow_Nap = 3.37;                           
        Koc_Nap = 10^((0.989*logKow_Nap)-0.346);
        Kd_Nap = foc*Koc_Nap;                        

        pb = 1.68;
        n = 0.367;
        
        RTol = 1+(pb/n)*Kd_Tol;
        vcTol = Vp/RTol;        
        TdTolR = 0;             
        TdITolR = vcTol*Dt;     
        
        RNap = 1+(pb/n)*Kd_Nap;
        vcNap = Vp/RNap;       
        TdNapR = 0;             
        TdINapR = vcNap*Dt;     
 
        Td_i = zeros(1, 50);
        TdTolR_i = zeros(1, 50);
        TdNapR_i = zeros(1, 50);
        Si_Tol_i = zeros(1, 50);
        Si_Nap_i = zeros(1, 50);
        Cg_Tol_i = zeros(1, 50);
        Cg_Nap_i = zeros(1, 50);
        Csoil_Tol_i = zeros(1, 50);
        Csoil_Nap_i = zeros(1, 50);
        Mt_i = zeros(1, 50);
            
        Cg_Tol = 0;
        Cg_Nap = 0;
        Csoil_Tol = 0;
        Csoil_Nap = 0;
        
        concentration_ok=0.0001;    
        condition = 1;              
  
        % END reset
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
        
end