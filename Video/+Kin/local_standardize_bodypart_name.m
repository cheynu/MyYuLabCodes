function bodypart_name_std = local_standardize_bodypart_name(bodypart_name)
bodypart_name_std = string(bodypart_name);

bodypart_name_std = replace(bodypart_name_std, "LeftPaw",  "Paw");
bodypart_name_std = replace(bodypart_name_std, "RightPaw", "Paw");
bodypart_name_std = replace(bodypart_name_std, "LeftEar",  "Ear");
bodypart_name_std = replace(bodypart_name_std, "RightEar", "Ear");
end