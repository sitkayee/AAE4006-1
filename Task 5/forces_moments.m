 % Input:
%       x: 12 states
%       delta: 4 control surfaces
%       wind: 6 wind parameters. three for steady wind and three for gust
%       "P" stores all the necessary parameters of the aircraft and atomasphere.
%       For example, the mass of the aircraft can be extracted by P.mass;
%       the gravity constant can be extracted by P.gravity;
%       and mean chord of the aircraft wing can be extracted by P.c; etc.
%       The names of the parameters are consistent with the lecture notes.

% Output:
%       "out" will contrain the overall Force and Torque; 
%                           the airspeed magnitude Va;
%                           the angle of attack alpha;
%                           the sideslip angle beta; and 
%                           the wind in NED frame w_n, w_e, w_d.

function out = forces_moments(x, delta, wind, P)
    pn      = x(1);
    pe      = x(2);
    pd      = x(3);
    u       = x(4);
    v       = x(5);
    w       = x(6);
    phi     = x(7);
    theta   = x(8);
    psi     = x(9);
    p       = x(10);
    q       = x(11);
    r       = x(12);
    delta_e = delta(1);
    delta_a = delta(2);
    delta_r = delta(3);
    delta_t = delta(4);
    w_ns    = wind(1); % steady wind - North
    w_es    = wind(2); % steady wind - East
    w_ds    = wind(3); % steady wind - Down
    u_wg    = wind(4); % gust along body i-axis
    v_wg    = wind(5); % gust along body j-axis    
    w_wg    = wind(6); % gust along body k-axis

    % Define transformation matrix from vehicle frame to body frame
    R_v_b = [cos(theta)*cos(psi) cos(theta)*sin(psi) -sin(theta); sin(phi)*sin(theta)*cos(psi)-cos(phi)*sin(psi) sin(phi)*sin(theta)*sin(psi)+cos(phi)*cos(psi) sin(phi)*cos(theta); cos(phi)*sin(theta)*cos(psi)+sin(phi)*sin(psi) cos(phi)*cos(theta)*sin(psi)-sin(phi)*cos(psi) cos(phi)*cos(theta)];

    % Define transformation matrix from body frame to vehicle frame
    R_b_v = [cos(psi)*cos(theta) -sin(psi)*cos(phi)+cos(psi)*sin(theta)*sin(phi) sin(psi)*sin(phi)+cos(psi)*sin(theta)*cos(phi); sin(psi)*cos(theta) cos(psi)*cos(phi)+sin(psi)*sin(theta)*sin(phi) -cos(psi)*sin(phi)+sin(psi)*sin(theta)*cos(phi); -sin(theta) cos(theta)*sin(phi) cos(theta)*cos(phi)];

    % Compute overall wind data in body frame
    V_w_b =R_v_b*[w_ns; w_es; w_ds]+[u_wg; v_wg; w_wg];
    % Compute overall wind in NED frame
    V_w_NED =R_b_v*V_w_b ;

    % define the wind components in NED frame
    w_n = V_w_NED(1);
    w_e = V_w_NED(2);
    w_d = V_w_NED(3);
    
    % Compute airspeed vector in body frame
    V_a_b =[u;v;w]-V_w_b;
    
    % Compute airspeed magnitute
    Va =sqrt(V_a_b(1)^2+ V_a_b(2)^2+ V_a_b(3)^2) ;

    % Compute alpha and beta
    alpha =atan(V_a_b(3)/ V_a_b(1))  ;
    beta =asin(V_a_b(2)/Va) ;
    
    % Compute the parameters used in the models of forces and torques
    sigma_alpha = (1+exp(-P.M*(alpha-P.alpha0))+exp(P.M*(alpha+P.alpha0)))/...
                ((1+exp(-P.M*(alpha-P.alpha0)))*(1+exp(P.M*(alpha+P.alpha0))));
    C_L = (1-sigma_alpha)*(P.C_L_0+P.C_L_alpha*alpha)+...
         sigma_alpha*(2*sign(alpha)*sin(alpha)^2*cos(alpha));
    C_D = P.C_D_p+(P.C_L_0+P.C_L_alpha*alpha)^2/(pi*P.e*(P.b^2/P.S_wing));
    C_X = -C_D*cos(alpha)+C_L*sin(alpha);
    C_X_q = -P.C_D_q*cos(alpha)+P.C_L_q*sin(alpha);
    C_X_delta_e = -P.C_D_delta_e*cos(alpha)+P.C_L_delta_e*sin(alpha);
    C_Z = -C_D*sin(alpha)-C_L*cos(alpha);
    C_Z_q = -P.C_D_q*sin(alpha)-P.C_L_q*cos(alpha);
    C_Z_delta_e = -P.C_D_delta_e*sin(alpha)-P.C_L_delta_e*cos(alpha);
    
    % Gravitational force (ensure gForce is a column vector)
    gForce = [-P.mass*P.gravity*sin(theta); P.mass*P.gravity*cos(theta)*sin(phi); P.mass*P.gravity*cos(theta)*cos(phi)];
    
    % Aerodynamic force (ensure aForce is a column vector)
    aForce = (1/2)*P.rho*(Va^2)*P.S_wing*[C_X+C_X_q*P.c/(2*Va)*q+C_X_delta_e*delta_e;...
        P.C_Y_0+P.C_Y_beta*beta+P.C_Y_p*(P.b/2*Va)*p+P.C_Y_r*P.b/(2*Va)*r+P.C_Y_delta_a*delta_a+P.C_Y_delta_r*delta_r;...
        C_Z+C_Z_q*P.c/(2*Va)*q+C_Z_delta_e*delta_e];
    
    % Propulsion force (ensure pForce is a column vector)
    pForce =(1/2)*P.rho*P.S_prop*P.C_prop* [(P.k_motor*delta_t)^2-(Va)^2;0;0];
    
    % Overall force 
    Force = gForce + aForce + pForce;

    % Torques due to aerodynamics and propulsion (ensure Torque is a column vector)
    Torque = 1/2*P.rho*(Va^2)*P.S_wing*[...
        P.b*[P.C_L_0+P.C_ell_beta*beta+P.C_ell_p*P.b/(2*Va)*p+P.C_ell_r*P.b/(2*Va)*r+P.C_ell_delta_a*delta_a+P.C_ell_delta_r*delta_r];...
        P.c*[P.C_m_0+P.C_m_alpha*alpha+P.C_m_q*P.c/(2*Va)*q+P.C_m_delta_e*delta_e];...
        P.b*[P.C_n_0+P.C_n_beta*beta+P.C_n_p*P.b/(2*Va)*p+P.C_n_r*P.b/(2*Va)*r+P.C_n_delta_a*delta_a+P.C_n_delta_r*delta_r]...
        ]+    [-P.k_T_P*((P.k_Omega*delta_t))^2;0;0];


    % Construct the output vector
    out = [Force; Torque; Va; alpha; beta; w_n; w_e; w_d];
end


