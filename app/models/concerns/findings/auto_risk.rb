module Findings::AutoRisk
  extend ActiveSupport::Concern

  included do
    before_validation :assign_auto_risk, if: :automatic_risk?

    PROBABILITIES = {
      rare:           1,
      unlikely:       2,
      possible:       3,
      probable:       4,
      almost_certain: 5
    }

    IMPACT_RISKS = {
      small:    1,
      low:      2,
      moderate: 3,
      high:     4,
      critical: 5
    }

    STATE_REGULATIONS = {
      not_exist:  200,
      inadequate: 100,
      exist:      0
    }

    DEGREE_COMPLIANCE = {
      fails:     100,
      partially: 50,
      comply:    0
    }

    OBSERVATION_ORIGINATED_TESTS = {
      design:     150,
      compliance: 75,
      sustantive: 75
    }

    SAMPLE_DEVIATION = {
      less_expected: 150,
      most_expected: 0
    }

    IMPACT_RISKS_BIC = {
      high:     150,
      moderate: 75,
      low:      0
    }

    FREQUENCIES = {
      high:     100,
      moderate: 50,
      low:      0
    }

    EXTERNAL_REPEATED = {
      repeated:    150,
      no_repeated: 0
    }
  end

  def automatic_risk?
    !manual_risk
  end

  def bic_risks_types
    {
      0 => 0,
      1 => 350.01,
      2 => 625.01
    }
  end

  module ClassMethods
    def auto_risk_thresholds
      {
        risks[:low]    => 4,
        risks[:medium] => 10,
        risks[:high]   => 100
      }
    end



    def probabilities
      PROBABILITIES
    end

    def impact_risks
      IMPACT_RISKS
    end

    def impact_risks_bic
      IMPACT_RISKS_BIC
    end

    def state_regulations
      STATE_REGULATIONS
    end

    def degree_compliance
      DEGREE_COMPLIANCE
    end

    def observation_origination_tests
      OBSERVATION_ORIGINATED_TESTS
    end

    def sample_deviation
      SAMPLE_DEVIATION
    end

    def frequencies
      FREQUENCIES
    end

    def external_repeated
      EXTERNAL_REPEATED
    end
  end

  private

    def assign_auto_risk
      if probability && impact_risk && USE_SCOPE_CYCLE
        result  = probability * impact_risk
        risk, _ = self.class.auto_risk_thresholds.detect do |_, threshold|
          result <= threshold
        end

        self.risk = risk
      elsif Current.conclusion_pdf_format == 'bic'
        self.risk
      else
        self.risk = nil
      end
    end
end
