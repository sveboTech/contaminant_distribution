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
Td_i = zeros(1, 10);
TdTolR_i = zeros(1, 10);
TdNapR_i = zeros(1, 10);
Si_Tol_i = zeros(1, 10);
Si_Nap_i = zeros(1, 10);
Cg_Tol_i = zeros(1, 10);
Cg_Nap_i = zeros(1, 10);
Csoil_Tol_i = zeros(1, 10);
Csoil_Nap_i = zeros(1, 10);
Mt_i = zeros(1, 10); 

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
     
hpopup = uicontrol('Style','popupmenu',...
           'String',{'With constraints','Without constraints'},...
           'Position',[320,yPos-1,120,25],...
           'Callback',{@popup_menu_Callback});
    
hpopupFoc = uicontrol('Style','popupmenu',...
           'String',{'foc = 0.0008','foc = 0.00245','foc = 0.0041'},...
           'Position',[450,yPos-1,90,25],...
           'Callback',{@popupFoc_menu_Callback});
       
hpopupKl = uicontrol('Style','popupmenu',...
           'String',{'Toluene kl = 0.009',...
           'Toluene kl = 0.065', 'Toluene kl = 0.02475',...
           'Naphthalene kl = 0.002686','Naphthalene kl = 0'},...
           'Position',[550,yPos-1,150,25],...
           'Callback',{@popupKl_menu_Callback});       
    
% END GUI AND POSITIONING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function popupKl_menu_Callback(source,eventdata)
        %Set selected data.
        val = source.Value;
        
        switch val;
            case 1
                k1_Tol = k1_TolZ;
            case 2
                k1_Tol = k1_TolZMix ;
            case 3
                k1_Tol = k1_TolW;
            case 4
                k1_Nap = k1_NapW;
            case 5
                k1_Nap = k1_NapZ;
        end
        
    end


    function popupFoc_menu_Callback(source,eventdata)
        %Set selected data.
        val = source.Value;
        
        switch val;
            case 1
                foc = 0.0008;
            case 2
                foc = 0.00245;
            case 3
                foc = 0.0041;
        end
        
    end

    %Setting up the Pop-Up
    function popup_menu_Callback(source,eventdata) 
      %Set selected data.
      val = source.Value;
      %resetVariables();
      
      switch val;
          %case 'With retardation'
          case 1
              current_data = 1; %'With retardation'
              
          case 2
              current_data = 2; %'Without retardation'
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

    % clear axes before plotting
    cla(ha);
    
    switch str
        case 'toluene'
            if current_data == 1
            
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
                text(0.985,0.75,strConsStart_T,'Units','Normalized','HorizontalAlignment','right');
                strConsEnd_T=['\color{red}End: ',num2str(Si_Tol),' mg/l'];
                text(0.985,0.70,strConsEnd_T,'Units','Normalized','HorizontalAlignment','right');
                
                % Toluene text, gas-concentration
                strConsStart_N=['\color{blue}Start: ',num2str(Cg_Tol_i(1)),' g/m^3'];
                text(0.985,0.65,strConsStart_N,'Units','Normalized','HorizontalAlignment','right');
                strConsEnd_N=['\color{blue}End: ', num2str(Cg_Tol),' g/m^3'];
                text(0.985,0.60,strConsEnd_N,'Units','Normalized','HorizontalAlignment','right');
                
                % Toluene text, sorption
                strConsStart_N=['\color{green}Start: ',num2str(Csoil_Tol_i(1)),' mg/kg'];
                text(0.985,0.55,strConsStart_N,'Units','Normalized','HorizontalAlignment','right');
                strConsEnd_N=['\color{green}End: ', num2str(Csoil_Tol),' mg/kg'];
                text(0.985,0.50,strConsEnd_N,'Units','Normalized','HorizontalAlignment','right');
                
                %Text time & distance
                Time_T=['\color{gray}Time: ',num2str(Mt_i(t),'%.2f'),' days.'];
                text(0.985,0.40,Time_T,'Units','Normalized','HorizontalAlignment','right');
                
                Distance_T=['\color{gray}Distance: ',num2str(TdTolR_i(t),'%.2f'),' meters.'];
                text(0.985,0.35,Distance_T,'Units','Normalized','HorizontalAlignment','right');
                hold off

                leg = legend('Water','Gas','Soil');
                title(leg,'Concentrations')
                leg.Visible = 'on';
                
                ax = f.CurrentAxes;
                ax.XTickLabelRotation = -45;
            
            else
          
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
                text(0.985,0.75,strConsStart_T,'Units','Normalized','HorizontalAlignment','right');
                strConsEnd_T=['\color{red}End: ',num2str(Si_Tol),' mg/l'];
                text(0.985,0.70,strConsEnd_T,'Units','Normalized','HorizontalAlignment','right');
                
                % Toluene text, gas-concentration
                strConsStart_N=['\color{blue}Start: ',num2str(Cg_Tol_i(1)),' g/m^3'];
                text(0.985,0.65,strConsStart_N,'Units','Normalized','HorizontalAlignment','right');
                strConsEnd_N=['\color{blue}End: ', num2str(Cg_Tol),' g/m^3'];
                text(0.985,0.60,strConsEnd_N,'Units','Normalized','HorizontalAlignment','right');
                
                %Text time & distance
                Time_T=['\color{gray}Time: ',num2str(Mt_i(t),'%.2f'),' days.'];
                text(0.985,0.50,Time_T,'Units','Normalized','HorizontalAlignment','right');
                
                Distance_T=['\color{gray}Distance: ',num2str(Td_i(t),'%.2f'),' meters.'];
                text(0.985,0.45,Distance_T,'Units','Normalized','HorizontalAlignment','right');
                       
                hold off
                
                leg = legend('Water','Gas');
                title(leg,'Concentrations')
                leg.Visible = 'on';
                
                ax = f.CurrentAxes;
                ax.XTickLabelRotation = -45;            
            end
            
        case 'naphthalene'
            if current_data == 1 %With retardation
               
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
                text(0.985,0.75,strConsStart_T,'Units','Normalized','HorizontalAlignment','right');
                strConsEnd_T=['\color{red}End: ',num2str(Si_Nap),' mg/l'];
                text(0.985,0.70,strConsEnd_T,'Units','Normalized','HorizontalAlignment','right');
                
                strConsStart_N=['\color{blue}Start: ',num2str(Cg_Nap_i(1)),' g/m^3'];
                text(0.985,0.65,strConsStart_N,'Units','Normalized','HorizontalAlignment','right');
                strConsEnd_N=['\color{blue}End: ', num2str(Cg_Nap),' g/m^3'];
                text(0.985,0.60,strConsEnd_N,'Units','Normalized','HorizontalAlignment','right');
                
                % Naphthalene text, sorption
                strConsStart_N=['\color{green}Start: ',num2str(Csoil_Nap_i(1)),' mg/kg'];
                text(0.985,0.55,strConsStart_N,'Units','Normalized','HorizontalAlignment','right');
                strConsEnd_N=['\color{green}End: ', num2str(Csoil_Nap),' mg/kg'];
                text(0.985,0.50,strConsEnd_N,'Units','Normalized','HorizontalAlignment','right');
                
                %Text time & distance
                Time_T=['\color{gray}Time: ',num2str(Mt_i(t),'%.2f'),' days.'];
                text(0.985,0.40,Time_T,'Units','Normalized','HorizontalAlignment','right');
                
                Distance_T=['\color{gray}Distance: ',num2str(TdNapR_i(t),'%.2f'),' meters.'];
                text(0.985,0.35,Distance_T,'Units','Normalized','HorizontalAlignment','right');
                
                hold off             
                
                leg = legend('Water','Gas','Soil');
                title(leg,'Concentrations')
                leg.Visible = 'on';
                
                ax = f.CurrentAxes;
                ax.XTickLabelRotation = -45;       
                
            else

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
                text(0.985,0.75,strConsStart_T,'Units','Normalized','HorizontalAlignment','right');
                strConsEnd_T=['\color{red}End: ',num2str(Si_Nap),' mg/l'];
                text(0.985,0.70,strConsEnd_T,'Units','Normalized','HorizontalAlignment','right');
                
                strConsStart_N=['\color{blue}Start: ',num2str(Cg_Nap_i(1)),' g/m^3'];
                text(0.985,0.65,strConsStart_N,'Units','Normalized','HorizontalAlignment','right');
                strConsEnd_N=['\color{blue}End: ', num2str(Cg_Nap),' g/m^3'];
                text(0.985,0.60,strConsEnd_N,'Units','Normalized','HorizontalAlignment','right');
                
                %Text time & distance
                Time_T=['\color{gray}Time: ',num2str(Mt_i(t),'%.2f'),' days.'];
                text(0.985,0.50,Time_T,'Units','Normalized','HorizontalAlignment','right');
                
                Distance_T=['\color{gray}Distance: ',num2str(Td_i(t),'%.2f'),' meters.'];
                text(0.985,0.45,Distance_T,'Units','Normalized','HorizontalAlignment','right');

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
        
%%-----   Do not reset (manual value-change)    
%         k1_TolW = 0.02475;
%         k1_NapW = 0.002686;
%         
%         %Values after Zheng et al. 2001
%         k1_TolZ = 0.009;            %Toluene Zheng
%         k1_TolZMix = 0.065;         %Mean toluene mixed with other1: 0.065
%         k1_NapZ = 0;
%         
%         k1_Tol = k1_TolZ;           %Change values for different scenarios
%         k1_Nap = k1_NapW;
%%-----      
        Ct_Tol = 0;                
        Ct_Nap = 0;                 
        Ct_Tol_Diff = 0;            
        Ct_Nap_Diff = 0;
        
        DTimeID = Dt/(60*60*24);  
        %Do not reset foc (manual value-change)
        %foc = 0.0008;    %foc: min=0.0008, max=0.0041, avg=0.00245
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
 
        Td_i = zeros(1, 10);
        TdTolR_i = zeros(1, 10);
        TdNapR_i = zeros(1, 10);
        Si_Tol_i = zeros(1, 10);
        Si_Nap_i = zeros(1, 10);
        Cg_Tol_i = zeros(1, 10);
        Cg_Nap_i = zeros(1, 10);
        Csoil_Tol_i = zeros(1, 10);
        Csoil_Nap_i = zeros(1, 10);
        Mt_i = zeros(1, 10);
            
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