function ber = Calculate_Error(predictions, labels)
shape = size(labels);
ber = sum(sum(predictions(1:shape(1),:) ~= labels))/(shape(1)*shape(2));
end

