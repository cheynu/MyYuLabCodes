function field = apply_occupancy_mask_to_field(field, mask)
%APPLY_OCCUPANCY_MASK_TO_FIELD Replace unsupported regions with NaN.

if ~isequal(size(field.F), size(mask))
    error('field.F and mask must have the same size.');
end

field.F_masked = field.F;
field.F_masked(~mask) = NaN;
field.support_mask = mask;
end