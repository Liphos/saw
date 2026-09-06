#!/bin/bash
#SBATCH --job-name=saw_k_kl_sweep
#SBATCH --output=logs/kl_sweep_%A_%a.out
#SBATCH --error=logs/kl_sweep_%A_%a.err
#SBATCH --array=0-249  # 2 envs * 5 kl_alphas * 5 subgoal_steps * 5 seeds
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=10
#SBATCH --gres=gpu:volta:1
#SBATCH --constraint=volta32gb

unset SLURM_CPU_BIND

# Cross sweep of the subgoal horizon k against the waypoint temperature kl_alpha.
# SAW only: kl_alpha does not exist in HIQL.
SEEDS=(3917 3502 8948 9460 4729)
ENVS=(
    "antmaze-large-navigate-v0"
    "cube-double-play-v0"
)
SUBGOAL_STEPS=(5 10 25 50 100)
KL_ALPHAS=(0.1 0.3 1.0 3.0 5.0)

NUM_ENVS=${#ENVS[@]}
NUM_KL_ALPHAS=${#KL_ALPHAS[@]}
NUM_SUBGOAL_STEPS=${#SUBGOAL_STEPS[@]}
ENV_IDX=$((SLURM_ARRAY_TASK_ID % NUM_ENVS))
KL_ALPHA_IDX=$(((SLURM_ARRAY_TASK_ID / NUM_ENVS) % NUM_KL_ALPHAS))
SUBGOAL_STEP_IDX=$(((SLURM_ARRAY_TASK_ID / (NUM_ENVS * NUM_KL_ALPHAS)) % NUM_SUBGOAL_STEPS))
SEED_IDX=$((SLURM_ARRAY_TASK_ID / (NUM_ENVS * NUM_KL_ALPHAS * NUM_SUBGOAL_STEPS)))

SEED=${SEEDS[$SEED_IDX]}
ENV=${ENVS[$ENV_IDX]}
SUBGOAL_STEP=${SUBGOAL_STEPS[$SUBGOAL_STEP_IDX]}
KL_ALPHA=${KL_ALPHAS[$KL_ALPHA_IDX]}

source .venv/bin/activate

# Both k and kl_alpha are swept, so no per-env override for either.
EXTRA_ARGS=(
    "--agent.subgoal_steps=${SUBGOAL_STEP}"
    "--agent.kl_alpha=${KL_ALPHA}"
)

srun python main.py \
    --env_name="$ENV" \
    --eval_episodes=50 \
    --agent="agents/saw.py" \
    --seed="$SEED" \
    --run_group="saw_k_kl_sweep" \
    "${EXTRA_ARGS[@]}"
