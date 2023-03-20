function mustBeMemberi(value,S)
% mustBeMember, but ignore case
    val = lower(value);
    s = lower(S);
    mustBeMember(val,s)
end