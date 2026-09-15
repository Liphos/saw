#!/bin/bash
#SBATCH --job-name=sweep_alpha_norm
#SBATCH --output=logs/sweep_alpha_norm_%A_%a.out
#SBATCH --error=logs/sweep_alpha_norm_%A_%a.err
#SBATCH --array=0-59  # 2 algos * 6 envs * 5 seeds * 1 alpha
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=10
#SBATCH --gres=gpu:volta:1
#SBATCH --constraint=volta32gb

unset SLURM_CPU_BIND

SEEDS=(3917 3502 8948 9460 4729)
ALGOS=("hiql" "saw")
ENVS=(
    "pointmaze-giant-navigate-v0"
    "pointmaze-large-navigate-v0"
    "cube-single-play-v0"
    "cube-double-play-v0"
    "humanoidmaze-large-navigate-v0"
    "humanoidmaze-giant-navigate-v0"
)
HIGH_ALPHAS=(0.5)

NUM_ALGOS=${#ALGOS[@]}
NUM_ENVS=${#ENVS[@]}
NUM_HIGH_ALPHAS=${#HIGH_ALPHAS[@]}
ALGO_IDX=$((SLURM_ARRAY_TASK_ID % NUM_ALGOS))
ENV_IDX=$(((SLURM_ARRAY_TASK_ID / NUM_ALGOS) % NUM_ENVS))
HIGH_ALPHA_IDX=$(((SLURM_ARRAY_TASK_ID / (NUM_ALGOS * NUM_ENVS)) % NUM_HIGH_ALPHAS))
SEED_IDX=$((SLURM_ARRAY_TASK_ID / (NUM_ALGOS * NUM_ENVS * NUM_HIGH_ALPHAS)))

SEED=${SEEDS[$SEED_IDX]}
ALGO=${ALGOS[$ALGO_IDX]}
ENV=${ENVS[$ENV_IDX]}
HIGH_ALPHA=${HIGH_ALPHAS[$HIGH_ALPHA_IDX]}

source .venv/bin/activate

EXTRA_ARGS=()

if [ "$ENV" = "antmaze-giant-navigate-v0" ]; then
    EXTRA_ARGS+=("--agent.discount=0.995")
fi

case "$ALGO" in
    saw)
        EXTRA_ARGS+=("--agent.kl_alpha=${HIGH_ALPHA}")
        ;;
    hiql)
        EXTRA_ARGS+=("--agent.high_alpha=${HIGH_ALPHA}")
        ;;
esac

srun python main.py \
    --env_name="$ENV" \
    --eval_episodes=50 \
    --agent="agents/${ALGO}.py" \
    --seed="$SEED" \
    --run_group="${ALGO}_sweep_alpha_norm" \
    "${EXTRA_ARGS[@]}"
