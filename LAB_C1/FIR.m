%%==============================================================================================
%    UNIVERSITÉ DU QUÉBEC A TROIS-RIVIERES
%    Département de génie électrique et de génie informatique
%    COURS: GEI-1064 Conception en VLSI
%    Date: Automne 2023
%%=============================================================================================
clear all;  % Effacement des memoires des toutes les memoires et fonctions
close all;  % On ferme toutes les figures en cours
clc;        % Effacement des commandes precedement tappees dans la Command Window
seed = 1; randn('state', seed); %-- pour avoir toujours la même séquence aléatoire
% >>> NE PAS EFFACER LA SORTIE SIMULINK SI ELLE EXISTE DEJA
keepOut = exist('Out_sysgen','var'); 
if keepOut, Out_sysgen_saved = Out_sysgen; end

%-- Paramètres ------------------------------------------------------------
Nseq  = 100;
N_Bit = 16;

Fs = 20e6;           % 20 MHz
Ts = 1/Fs;           % 50 ns

%%=========================================================================
% VIRGULE FLOTTANTE (précision maximale)
%%=========================================================================
xin =0.2*randn(Nseq,1);
w1  =0.2*randn(Nseq,1);
w2  =0.2*randn(Nseq,1);
w3  =0.2*randn(Nseq,1);
w4  =0.2*randn(Nseq,1);
w5  =0.2*randn(Nseq,1);

%%=========================================================================
% FIR ==> VIRGULE FIXE (précision limitée par le nb. de bit)
%=========================================================================
%-- Préallocation (propre, évite warnings)
xin_fix = zeros(Nseq,2);
w1_fix  = zeros(Nseq,2);
w2_fix  = zeros(Nseq,2);
w3_fix  = zeros(Nseq,2);
w4_fix  = zeros(Nseq,2);
w5_fix  = zeros(Nseq,2);

%-- Conversion des entrées en décimale représentable en binaire
for n=1:Nseq
    xin_fix(n,2)=Quantize_func(xin(n,1),N_Bit);
    w1_fix(n,2)=Quantize_func(w1(n,1),N_Bit);
    w2_fix(n,2)=Quantize_func(w2(n,1),N_Bit);
    w3_fix(n,2)=Quantize_func(w3(n,1),N_Bit);
    w4_fix(n,2)=Quantize_func(w4(n,1),N_Bit);
    w5_fix(n,2)=Quantize_func(w5(n,1),N_Bit);
end

%-- Formattage des données pour Simulink
time = (0:Nseq-1) * Ts;     % 100 points exactement (0 ... 99)*50ns
xin_fix(:,1) = time;
w1_fix(:,1)  = time;
w2_fix(:,1)  = time;
w3_fix(:,1)  = time;
w4_fix(:,1)  = time;
w5_fix(:,1)  = time;

%%=========================================================================
% IMPORTANT (Option 2 demandée) :
% On garde les noms EXACTS exigés (xin_fix, w1_fix...) mais en "timeseries"
% -> sortie scalaire à chaque pas -> compatible Gateway In (plus de [100x2])
%%=========================================================================
t_col = time(:);

xin_fix = timeseries(xin_fix(:,2), t_col);
w1_fix  = timeseries(w1_fix(:,2),  t_col);
w2_fix  = timeseries(w2_fix(:,2),  t_col);
w3_fix  = timeseries(w3_fix(:,2),  t_col);
w4_fix  = timeseries(w4_fix(:,2),  t_col);
w5_fix  = timeseries(w5_fix(:,2),  t_col);

%%=========================================================================
% (MATLAB interne) Pour la suite de TON code, on récupère les valeurs
% sous forme vecteur (sinon xin_fix(:,2) n'existe plus car xin_fix est timeseries)
%%=========================================================================
xin_fix_val = xin_fix.Data;
w1_fix_val  = w1_fix.Data;
w2_fix_val  = w2_fix.Data;
w3_fix_val  = w3_fix.Data;
w4_fix_val  = w4_fix.Data;
w5_fix_val  = w5_fix.Data;

%-- Mise sous-forme matricielle de l'entrée Yin (avec les *_val)
xin_fix_mat = [xin_fix_val ...
               [0;xin_fix_val(1:end-1)] ...
               [0;0;xin_fix_val(1:end-2)] ...
               [0;0;0;xin_fix_val(1:end-3)] ...
               [0;0;0;0;xin_fix_val(1:end-4)]];

%--> Quantification des signaux A et B -----------------------
prod1 = zeros(Nseq,1); prod2 = zeros(Nseq,1); prod3 = zeros(Nseq,1); prod4 = zeros(Nseq,1); prod5 = zeros(Nseq,1);
prod1_fix = zeros(Nseq,1); prod2_fix = zeros(Nseq,1); prod3_fix = zeros(Nseq,1); prod4_fix = zeros(Nseq,1); prod5_fix = zeros(Nseq,1);
Sout_part1 = zeros(Nseq,1); Sout_part2 = zeros(Nseq,1); Sout_part3 = zeros(Nseq,1);
Sout_part1_fix = zeros(Nseq,1); Sout_part2_fix = zeros(Nseq,1); Sout_part3_fix = zeros(Nseq,1);
Sout = zeros(Nseq,1);

Sout_fix = zeros(Nseq,2);

for n=1:Nseq
    prod1(n,1) = xin_fix_mat(n,1)*w1_fix_val(n);   % à chaque clk, les w sont changés eux-aussi
    prod2(n,1) = xin_fix_mat(n,2)*w2_fix_val(n);
    prod3(n,1) = xin_fix_mat(n,3)*w3_fix_val(n);
    prod4(n,1) = xin_fix_mat(n,4)*w4_fix_val(n);
    prod5(n,1) = xin_fix_mat(n,5)*w5_fix_val(n);

    prod1_fix(n,1) = Quantize_func(prod1(n,1),2*N_Bit);
    prod2_fix(n,1) = Quantize_func(prod2(n,1),2*N_Bit);
    prod3_fix(n,1) = Quantize_func(prod3(n,1),2*N_Bit);
    prod4_fix(n,1) = Quantize_func(prod4(n,1),2*N_Bit);
    prod5_fix(n,1) = Quantize_func(prod5(n,1),2*N_Bit);

    Sout_part1(n,1) = prod1_fix(n,1)+ prod2_fix(n,1);
    Sout_part1_fix(n,1) =Quantize_func(Sout_part1(n,1),2*N_Bit);

    Sout_part2(n,1) = Sout_part1_fix(n,1)+ prod3_fix(n,1);
    Sout_part2_fix(n,1) =Quantize_func(Sout_part2(n,1),2*N_Bit);

    Sout_part3(n,1) = Sout_part2_fix(n,1)+ prod4_fix(n,1);
    Sout_part3_fix(n,1) =Quantize_func(Sout_part3(n,1),2*N_Bit);

    Sout(n,1) = Sout_part3_fix(n,1) + prod5_fix(n,1);
    Sout_fix(n,2) = Quantize_func(Sout(n,1),2*N_Bit);
end
Sout_fix(:,1) = time;

%END PART 1
%%=========================================================================
%START PART 2

%==========================================================================
% Courbes de comparaisons
%==========================================================================

%=== Comparaison des résultats VHDL et MATLAB =============================

figure;
plot(Out_sysgen(1:end-1),'o-b')
hold on
plot(Sout_fix(:,2),'*-r')
hold off
legend('S Sysgen','S Matlab')
xlabel('Échantillons')
ylabel( 'Amplitudes')
title('FIR - Sortie Sysgen et Matlab')
axis([1 length(Sout_fix) -0.35 0.35])