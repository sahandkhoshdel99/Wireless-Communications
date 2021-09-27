function [output, Hk] = Channel(input, SNR_dB, type)
message_len = length(input);
if(type == "ray")
    Hk = raylrnd(1, 1, message_len);
else
    Hk = ones(1, message_len); 
end 
output = Hk.*input;
output = awgn(output, SNR_dB);
end

