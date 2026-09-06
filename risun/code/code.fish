set -l code_profiles web common rust go java sql

for profile in $code_profiles
    eval "
function code_$profile
    code \$argv --profile $profile
end
"
end

