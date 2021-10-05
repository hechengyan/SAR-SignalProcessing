clc
clear
close all
%% 参数设置
%  已知参数--》距离向参数
R_eta_c = 20e+3;                % 景中心斜距
Tr = 2.5e-6;                    % 发射脉冲时宽
Kr = 20e+12;                    % 距离向调频率
alpha_os_r = 1.2;               % 距离过采样率
Nrg = 320;                      % 距离线采样点数
%  计算参数--》距离向参数
Bw = abs(Kr)*Tr;                % 距离信号带宽
Fr = alpha_os_r*Bw;             % 距离向采样率
Nr = round(Fr*Tr);              % 距离采样点数(脉冲序列长度)
%  已知参数--》方位向参数
c = 3e+8;                       % 电磁传播速度
Vr = 150;                       % 等效雷达速度
Vs = Vr;                        % 卫星平台速度
Vg = Vr;                        % 波束扫描速度
f0 = 5.3e+9;                    % 雷达工作频率
Delta_f_dop = 80;               % 多普勒带宽
alpha_os_a = 1.25;              % 方位过采样率
Naz = 256;                      % 距离线数
theta_r_c = 0*pi/180;       	% 波束斜视角
%  计算参数--》方位向参数
lambda = c/f0;                  % 雷达工作波长
t_eta_c = -R_eta_c*sin(theta_r_c)/Vr;
                                % 景中心波束中心穿越时刻
f_eta_c = 2*Vr*sin(theta_r_c)/lambda;
                                % 多普勒中心频率
La = 0.886*2*Vs*cos(theta_r_c)/Delta_f_dop;               
                                % 实际天线长度
Fa = alpha_os_a*Delta_f_dop;    % 方位向采样率
Ta = 0.886*lambda*R_eta_c/(La*Vg*cos(theta_r_c));
                                % 目标照射时间
R0 = R_eta_c*cos(theta_r_c);    % 景中心最短斜距
theta_bw = 0.886*lambda/La;     % 方位向3dB波束宽度
%  参数计算
rho_r = c/(2*Fr);               % 距离向分辨率
rho_a = La/2;                   % 距离向分辨率
Trg = Nrg/Fr;                   % 发射脉冲时宽
Taz = Naz/Fa;                   % 目标照射时间
d_t_tau = 1/Fr;                 % 距离采样时间间隔
d_t_eta = 1/Fa;                 % 方位采样时间间隔
d_f_tau = Fr/Nrg;               % 距离采样频率间隔    
d_f_eta = Fa/Naz;               % 方位采样频率间隔
%% 目标设置
%  设置目标点相对于景中心之间的距离
A_r =   0; A_a =   0;                                   % A点位置
B_r = -50; B_a = -50;                                   % B点位置
C_r = -50; C_a = +50;                                   % C点位置
D_r = +50; D_a = C_a + (D_r-C_r)*tan(theta_r_c);        % D点位置
%  得到目标点相对于景中心的位置坐标
A_x = R0 + A_r; A_Y = A_a;                              % A点坐标
B_x = R0 + B_r; B_Y = B_a;                              % B点坐标
C_x = R0 + C_r; C_Y = C_a;                              % C点坐标
D_x = R0 + D_r; D_Y = D_a;                              % D点坐标
NPosition = [A_x,A_Y;
             B_x,B_Y;
             C_x,C_Y;
             D_x,D_Y;];                                 % 设置数组
fprintf( 'A点坐标为[%+3.3f，%+3.3f]km\n', NPosition(1,1)/1e3, NPosition(1,2)/1e3 );
fprintf( 'B点坐标为[%+3.3f，%+3.3f]km\n', NPosition(2,1)/1e3, NPosition(2,2)/1e3 );
fprintf( 'C点坐标为[%+3.3f，%+3.3f]km\n', NPosition(3,1)/1e3, NPosition(3,2)/1e3 );
fprintf( 'D点坐标为[%+3.3f，%+3.3f]km\n', NPosition(4,1)/1e3, NPosition(4,2)/1e3 );
%  得到目标点的波束中心穿越时刻
Ntarget = 4;
Tar_t_eta_c = zeros(1,Ntarget);
for i = 1 : Ntarget
    DeltaX = NPosition(i,2) - NPosition(i,1)*tan(theta_r_c);
    Tar_t_eta_c(i) = DeltaX/Vs;
end
%  得到目标点的绝对零多普勒时刻
Tar_t_eta_o = zeros(1,Ntarget);
for i = 1 : Ntarget
    Tar_t_eta_o(i) = NPosition(i,2)/Vr;
end
%% 变量设置
%  时间变量 以景中心的零多普勒时刻作为方位向零点
t_tau = (-Trg/2:d_t_tau:Trg/2-d_t_tau) + 2*R_eta_c/c;   % 距离时间变量
t_eta = (-Taz/2:d_t_eta:Taz/2-d_t_eta) + t_eta_c(1);    % 方位时间变量
%  长度变量
r_tau = (t_tau*c/2)*cos(theta_r_c);                     % 距离长度变量                                                     
%  频率变量 
f_tau = fftshift(-Fr/2:d_f_tau:Fr/2-d_f_tau);           % 距离频率变量
f_tau = f_tau - round((f_tau-0)/Fr)*Fr;                 % 距离频率变量(可观测频率)                          
f_eta = fftshift(-Fa/2:d_f_eta:Fa/2-d_f_eta);           % 方位频率变量
f_eta = f_eta - round((f_eta-f_eta_c(1))/Fa)*Fa;        % 方位频率变量(可观测频率)
%% 坐标设置     
%  以距离时间为X轴，方位时间为Y轴
[t_tauX,t_etaY] = meshgrid(t_tau,t_eta);                % 设置距离时域-方位时域二维网络坐标
%  以距离长度为X轴，方位频率为Y轴                                                                                                            
[r_tauX,f_etaY] = meshgrid(r_tau,f_eta);                % 设置距离时域-方位频域二维网络坐标
%  以距离频率为X轴，方位频率为Y轴                                                                                                            
[f_tau_X,f_eta_Y] = meshgrid(f_tau,f_eta);              % 设置频率时域-方位频域二维网络坐标
%% 信号设置--》原始回波信号  
tic
wait_title = waitbar(0,'开始生成雷达原始回波数据 ...');  
pause(1);
srt = zeros(Naz,Nrg);
for i = 1 : 1
    %  计算目标点的瞬时斜距
    R_eta = sqrt( NPosition(i,1)^2 +...
                  Vr^2*(t_etaY-Tar_t_eta_o(i)).^2 );                      
    % 后向散射系数幅度
    A0 = [1,1,1,1]*exp(+1j*0);   
    % 距离向包络
    wr = (abs(t_tauX-2*R_eta/c) <= Tr/2);                               
    % 方位向包络
    wa = sinc(0.886*atan(Vg*(t_etaY-Tar_t_eta_c(i))/NPosition(i,1))/theta_bw).^2;      
    %  接收信号叠加
    srt_tar = A0(i)*wr.*wa.*exp(-1j*4*pi*f0*R_eta/c)...
                          .*exp(+1j*pi*Kr*(t_tauX-2*R_eta/c).^2);                                                           
    srt = srt + srt_tar; 
    
    pause(0.001);
    Time_Trans   = Time_Transform(toc);
    Time_Disp    = Time_Display(Time_Trans);
    Display_Data = num2str(roundn(i/Ntarget*100,-1));
    Display_Str  = ['Computation Progress ... ',Display_Data,'%',' --- ',...
                    'Using Time: ',Time_Disp];
    waitbar(i/Ntarget,wait_title,Display_Str)
    
end
pause(1);
close(wait_title);
toc
%% 信号设置--》一次距离压缩
%  计算滤波器           
%  信号变换-->方式三：根据脉冲频谱特性直接在频域生成频域匹配滤波器
%  加窗函数
window_3 = kaiser(Nrg,2.5)';                            % 时域窗
Window_3 = fftshift(window_3);                          % 频域窗
Hrf_3 = (abs(f_tau_X)<=Bw/2).*Window_3.*exp(+1j*pi*f_tau_X.^2/Kr);  
%  匹配滤波
Srf = fft(srt,Nrg,2);
Soutf_3 = Srf.*Hrf_3;
soutt_3 = ifft(Soutf_3,Nrg,2);
%% 信号设置--》方位向傅里叶变换
Srdf_3 = fft(soutt_3,Naz,1);
%% 信号设置--》距离徙动校正
RCM = lambda^2*r_tauX.*f_etaY.^2/(8*Vr^2);              % 需要校正的距离徙动量
RCM = R0 + RCM - R_eta_c;                               % 将距离徙动量转换到原图像坐标系中
offset = RCM/rho_r;                                     % 将距离徙动量转换为距离单元偏移量
%  插值函数校正
tic
wait_title = waitbar(0,'开始进行距离徙动校正 ...');  
pause(1);
R = 8;        % 插值核的长度 
kwin = kaiser(R,2.5).';
offset_ceil = ceil(offset);
Srdf_rcm_3 = zeros(Naz,Nrg);
for a_tmp = 1 : Naz
    for r_tmp = 1 : Nrg
        kernel = kwin.*sinc((offset(a_tmp,r_tmp)-offset_ceil(a_tmp,r_tmp))-(-R/2:1:R/2-1));
        points = r_tmp + offset_ceil(a_tmp,r_tmp) + (-R/2:1:R/2-1);
        kernel = kernel(points>0 & points<=Nrg);
        points = points(points>0 & points<=Nrg);
        kernal = kernel./sum(kernel);
        Srdf_rcm_3(a_tmp,r_tmp) = Srdf_3(a_tmp,points)*kernel';
    end
    
    pause(0.001);
    Time_Trans   = Time_Transform(toc);
    Time_Disp    = Time_Display(Time_Trans);
    Display_Data = num2str(roundn(a_tmp/Naz*100,-1));
    Display_Str  = ['Computation Progress ... ',Display_Data,'%',' --- ',...
                    'Using Time: ',Time_Disp];
    waitbar(a_tmp/Naz,wait_title,Display_Str)
        
end
pause(1);
close(wait_title);
toc
%% 信号设置--》方位压缩
%  变量设置
Ka = 2*Vr^2*cos(theta_r_c)^2/lambda./r_tauX; 
%  计算滤波器
Haf = exp(-1j*pi*f_etaY.^2./Ka);
%  匹配滤波
Soutf_3 = Srdf_rcm_3.*Haf;
soutt_3 = ifft(Soutf_3,Naz,1);